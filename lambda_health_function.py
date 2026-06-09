import boto3
import datetime
import json
import os

autoscaling = boto3.client('autoscaling')
cloudwatch = boto3.client('cloudwatch')
s3 = boto3.client('s3')
ec2 = boto3.client('ec2')

ASG_NAME = os.getenv('ASG_NAME')
BUCKET_NAME = os.getenv('BUCKET_NAME')
SNS_ARN = os.getenv('SNS_ARN')
AWS_VPC_ID = os.getenv('AWS_VPC_ID')

def get_instance_cpu(instance_id, start_time, end_time):
    response = cloudwatch.get_metric_statistics(
        Namespace='AWS/EC2',
        MetricName='CPUUtilization',
        Dimensions=[
            {'Name': 'InstanceId', 'Value': instance_id}
        ],
        StartTime=start_time,
        EndTime=end_time,
        Period=300,
        Statistics=['Average']
    )

    datapoints = response.get('Datapoints', [])
    if not datapoints:
        return 0

    latest = sorted(datapoints, key=lambda x: x['Timestamp'])[-1]
    return round(latest['Average'], 2)


def lambda_health_handler(event, context):
        
    end_time = datetime.now(datetime.timezone.utc)
    start_time = end_time - datetime.timedelta(minutes=10)

    report = {}

    asg_response = autoscaling.describe_auto_scaling_groups(
        AutoScalingGroupNames=[ASG_NAME]
    )

    if not asg_response.get('AutoScalingGroups'):
        return {
            'statusCode': 404,
            'body': f'ASG {ASG_NAME} not found'
        }

    asg = asg_response['AutoScalingGroups'][0]
    
    report['Time'] = end_time.isoformat()
    report['asg_name'] = ASG_NAME
    report['desired_capacity'] = asg.get('DesiredCapacity')
    report['min_size'] = asg.get('MinSize')
    report['max_size'] = asg.get('MaxSize')

    instance_report = []
    total_cpu = 0.0
    instance_count = 0

    for instance in asg.get('Instances', []):
        instance_id = instance.get('InstanceId')
        # Check if Findings are for intended WebServer
        try:
          response = ec2.describe_instances(
            InstanceIds=[instance_id]
          )

          vpc_id = response["Reservations"][0]["Instances"][0]["VpcId"]

          if vpc_id != AWS_VPC_ID:
              print("Ignoring finding from another VPC")
              return

          print("Processing finding")

        except Exception as e:
          print(str(e))
        
        cpu = get_instance_cpu(instance_id, start_time, end_time)

        total_cpu += cpu
        instance_count += 1

        instance_report.append({
            'instance_id': instance_id,
            'lifecycle_state': instance.get('LifecycleState'),
            'health_status': instance.get('HealthStatus'),
            'cpu_utilization': cpu
        })

    average_cpu = round(total_cpu / instance_count, 2) if instance_count > 0 else 0

    report['instance_count'] = instance_count
    report['average_cpu_utilization'] = average_cpu
    report['instances'] = instance_report

    scaling_response = autoscaling.describe_scaling_activities(
        AutoScalingGroupName=ASG_NAME,
        MaxRecords=20
    )

    activities = []
    for activity in scaling_response.get('Activities', []):
        activities.append({
            'activity_id': activity.get('ActivityId'),
            'description': activity.get('Description'),
            'cause': activity.get('Cause'),
            'status': activity.get('StatusCode'),
            'start_time': str(activity.get('StartTime'))
        })

    report['scaling_activities'] = activities

    key = f"asg-health-reports/asg_report_{end_time.strftime('%Y%m%d_%H%M%S')}.json"

    s3.put_object(
        Bucket=BUCKET_NAME,
        Key=key,
        Body=json.dumps(report, indent=4, default=str)
    )

    return {
        'statusCode': 200,
        'report_location': f"s3://{BUCKET_NAME}/{key}",
        'average_cpu_utilization': average_cpu
    }

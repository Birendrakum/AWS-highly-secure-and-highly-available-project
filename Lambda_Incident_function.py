import boto3
import datetime
import json
import os

cloudwatch = boto3.client('cloudwatch')
s3 = boto3.client('s3')
sns = boto3.client('sns')
waf = boto3.client('waf')
autoscaling = boto3.client('autoscaling')
ec2 = boto3.client('ec2')

BUCKET_NAME = os.getenv("BUCKET_NAME")
SNS_ARN = os.getenv("SNS_ARN")
ASG_NAME = os.getenv("ASG_NAME")
BACKUP_ASG_NAME = os.getenv("BACKUP_ASG_NAME")
WAF_IP_SET_ID = os.getenv("WAF_IP_SET_ID")
WAF_IP_SET_NAME = os.getenv("WAF_IP_SET_NAME")
QUARANTINE_SG_ID = os.getenv("QUARANTINE_SG_ID")
TARGET_GROUP_ARN = os.getenv("TARGET_GROUP_ARN")
AWS_VPC_ID = os.getenv("AWS_VPC_ID")

key = f"{datetime.now(datetime.timezone.utc)}-incident-report.json"

def log_to_s3(event):
    # Extract the data from cloudwatch logs
    report = {}
    report["type"] = event['details']['type']
    report["severity"] = event["detail"]["severity"]
    report['Targeted_on'] = report['resource']['resourceType']
    report['from_Ip'] = event['service']['action']['networkConnectionAction']['networkIpDetail']['ipAddressV4']   
        
    
    # store_finding_to_s3()
    s3.put_object(
        Bucket = BUCKET_NAME,
        Key = key,
        Body=json.dumps(report, indent=4, default=str) 
    )
    
    return report

def lambda_incident_handler(event, context):
  
    # Check if Findings are for intended WebServer
    try:
        instance_id = event["detail"]["resource"]["instanceDetails"]["instanceId"]

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
  
    severity = event["detail"]["severity"]

    if 4 <= severity <= 5:
      # Log data to s3
      report = log_to_s3(event)

    elif 5 < severity <= 7:
      # Log data to s3
      report = log_to_s3(event)
      
      # send notification to admin
      response = sns.publish(
      TopicArn=SNS_ARN,
      Subject=f'''
        Incident reported ! Medium Severity
        -------------------------------------------------
        Please check {BUCKET_NAME}/{key}
        ''',
      Message="Medium severity GuardDuty finding detected."
      )  

    elif severity >= 7:
      # store_finding_to_s3()
      report = log_to_s3(event,key)
      
      # block_malicious_ip()
      response = waf.get_ip_set(
        Name=WAF_IP_SET_NAME,
        Scope="REGIONAL",
        Id=WAF_IP_SET_ID
      )

      addresses = response["IPSet"]["Addresses"]
      lock_token = response["LockToken"]
      ip = report["from_Ip"]
      cidr = f"{ip}/32"

      if cidr not in addresses:
        addresses.append(cidr)

      waf.update_ip_set(
        Name=WAF_IP_SET_NAME,
        Scope="REGIONAL",
        Id=WAF_IP_SET_ID,
        Addresses=addresses,
        LockToken=lock_token
      )
      
      # switch to backup asg
      autoscaling.detach_load_balancer_target_groups(
        AutoScalingGroupName=ASG_NAME,
        TargetGroupARNs=[TARGET_GROUP_ARN]
      )

      autoscaling.attach_load_balancer_target_groups(
        AutoScalingGroupName=BACKUP_ASG_NAME,
        TargetGroupARNs=[TARGET_GROUP_ARN]
      )
      
      # isolate all ASG instance 
      response = autoscaling.describe_auto_scaling_groups(
        AutoScalingGroupNames=[ASG_NAME]
      )

      if not response["AutoScalingGroups"]:
        raise Exception(f"ASG {ASG_NAME} not found")

      instances = response["AutoScalingGroups"][0]["Instances"]
      
      isolated_instances = []
      for instance in instances:
        instance_id = instance["InstanceId"]
        isolated_instances.append(instance_id)
        ec2.modify_instance_attribute(
            InstanceId=instance_id,
            Groups=[QUARANTINE_SG_ID]
        )
    
      # send_sns_alert()
      response = sns.publish(
        TopicArn=SNS_ARN,
        Subject=f'''
          Incident reported !!! High Severity !!!
          -------------------------------------------------
          Event Details is stored in s3 bucket {BUCKET_NAME} with name {key}
          With isolated Instances:
          {isolated_instances}
          ''',
        Message="!!! High severity GuardDuty finding detected."
        )

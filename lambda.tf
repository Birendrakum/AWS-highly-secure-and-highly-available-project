resource "aws_lambda_function" "HealthReportGenerator" {
    function_name = "HealthReportGenerator"
    runtime = "python3.8"
    role = aws_iam_role.LambdaHealthReportGenerator-Role.arn
    handler = "lambda_health_function.lambda_health_handler"
    filename = "lambda_function.zip"
    source_code_hash = filebase64sha256("lambda_function.zip")
    environment {
        variables = {
            BUCKET_NAME = aws_s3_bucket.health_report_bucket.bucket
            SNS_ARN = data.aws_sns_topic.sns_existing.arn
            ASG_NAME = aws_autoscaling_group.WebServerASG.name
            AWS_VPC_ID = aws_vpc.VPC.id
        }
    }
}

resource "aws_iam_role" "LambdaHealthReportGenerator-Role" {
    name = "LambdaHealthReportGenerator-Role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action:
                  - "cloudwatch:GetMetricStatistics"
                  - "s3:PutObject"
                  - "auto-scaling:DescribeAutoScalingGroups"
                  - "ec2:Describe*"
                Effect = "Allow"
                Principal = {
                    Service = "lambda.amazonaws.com"
                }
            }
        ]
    })
}

resource "aws_lambda_function" "SecurityIncidentHandler" {
    function_name = "SecurityIncidentHandler"
    runtime = "python3.8"
    role = aws_iam_role.LambdaIncidentHandler-Role.arn
    handler = "lambda_Incident_function.lambda_incident_handler"
    filename = "lambda_function.zip"
    source_code_hash = filebase64sha256("lambda_function.zip")
    environment {
        variables = {
            BUCKET_NAME = aws_s3_bucket.incident_s3.bucket
            SNS_ARN = data.aws_sns_topic_existing.arn
            ASG_NAME = aws_autoscaling_group.WebServerASG.name
            BACKUP_ASG_NAME = aws_autoscaling_group.Backup-WebServerASG.name
            WAF_IP_SET_ID   = aws_wafv2_ip_set.blocked_ips.id
            WAF_IP_SET_NAME = aws_wafv2_ip_set.blocked_ips.name
            QUARANTINE_SG_ID = aws_security_group.Isolated_SG.id
            TARGET_GROUP_ARN = aws_lb_target_group.WebServerLB-TG.arn
            AWS_VPC_ID = aws_vpc.VPC.id
        }
    }
}

resource "aws_iam_role" "LambdaIncidentHandler-Role" {
    name = "LambdaIncidentHandler-Role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action:
                  - "cloudwatch:GetMetricStatistics"
                  - "cloudwatch:log:GetLogEvents"
                  - "s3:PutObject"
                  - "ec2:Get*",
                  - "ec2:Describe*"
                  - "ec2:Modify*",
                  - "ec2:Update*",
                  - "autoscaling:Describe*",
                  - "autoscaling:Get*",
                  - "autoscaling:Update*",
                  - "waf:Get*",
                  - "waf:Update*",
                  - "sns:Get*",
                  - "sns:Publish",
                  - "sns:Subscribe",
                  - "sns:Unsubscribe",
                  - "sns:DeleteTopic",
                  - "s3:put*"
                
                Effect = "Allow"
                Principal = {
                    Service = "lambda.amazonaws.com"
                }
            }
        ]
    })
}


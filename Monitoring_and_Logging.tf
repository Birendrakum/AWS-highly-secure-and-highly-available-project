# aws log group
resource "aws_cloudwatch_log_group" "cloudwatch_log_group" {
  name              = "/vpc/flowlogs"
  retention_in_days = 30
}

# AWS VPC flow log role
resource "aws_iam_role" "flow_logs_role" {
  name = "VPCFlowLogsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# AWS VPC flow log role policy attachment
resource "aws_iam_role_policy" "flow_logs_policy" {
  name = "VPCFlowLogsPolicy"
  role = aws_iam_role.flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# aws vpc flow log
resource "aws_flow_log" "vpc_flow_log" {
  vpc_id               = aws_vpc.VPC.id
  traffic_type         = "ALL"

  log_destination_type = "cloud-watch-logs"
  log_group_name       = aws_cloudwatch_log_group.cloudwatch_log_group.name
  iam_role_arn         = aws_iam_role.flow_logs_role.arn

  max_aggregation_interval = 60
}

# Enable guardduty
resource "aws_guardduty_detector" "Webserver_GuardDuty" {
  enable = true
}

# Custom Blocked IP set for WAF
resource "aws_wafv2_ip_set" "blocked_ips" {
  name               = "blocked-ips"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"

  addresses = []

  description = "IPs blocked by GuardDuty automation"
}


# Create WAF
resource "aws_wafv2_web_acl" "alb_waf" {
  name  = "alb-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "alb-web-acl"
    sampled_requests_enabled   = true
  }
  # Top Rule: My own custom blocked ip set
  rule {
  name     = "BlockedIPs"
  priority = 0

  action {
    block {}
  }

  statement {
    ip_set_reference_statement {
      arn = aws_wafv2_ip_set.blocked_ips.arn
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "BlockedIPs"
    sampled_requests_enabled   = true
  }
  }

  # First Rule: This will protect the LB from common web attacks
  rule {
  name     = "AWSManagedRulesCommonRuleSet"
  priority = 1

  override_action {
    none {}
  }

  statement {
    managed_rule_group_statement {
      vendor_name = "AWS"
      name        = "AWSManagedRulesCommonRuleSet"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "CommonRuleSet"
    sampled_requests_enabled   = true
  }
  }

  # Second Rule: This will block all malicious know IPs
  rule {
  name     = "AWSManagedRulesAmazonIpReputationList"
  priority = 2

  override_action {
    none {}
  }

  statement {
    managed_rule_group_statement {
      vendor_name = "AWS"
      name        = "AWSManagedRulesAmazonIpReputationList"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "IpReputation"
    sampled_requests_enabled   = true
  }
  }

  # Third Rule: This will check for command injection and malformed request
  rule {
  name     = "AWSManagedRulesKnownBadInputsRuleSet"
  priority = 3

  override_action {
    none {}
  }

  statement {
    managed_rule_group_statement {
      vendor_name = "AWS"
      name        = "AWSManagedRulesKnownBadInputsRuleSet"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "KnownBadInputs"
    sampled_requests_enabled   = true
  }
  }

  # Fourth Rule: This will check the request number from a particular ip within a specific time window
  rule {
  name     = "RateLimit"
  priority = 4

  action {
    block {}
  }

  statement {
    rate_based_statement {
      limit              = 1000
      aggregate_key_type = "IP"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "RateLimit"
    sampled_requests_enabled   = true
  }
}
}

# Attach WAF to ALB
resource "aws_wafv2_web_acl_association" "alb_assoc" {
  resource_arn = aws_lb.WebServerLB.arn
  web_acl_arn  = aws_wafv2_web_acl.alb_waf.arn
}


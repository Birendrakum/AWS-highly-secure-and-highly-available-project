resource "aws_eventbridge_rule" "Health_Report_Rule" {
    name = "health-report-rule"
    description = "Trigger Lambda function to generate health reports based on hourly basis"
    destination = aws_lambda_function.HealthReportGenerator.arn
    event_pattern = jsonencode({
        source = ["aws.events"]
        detail-type = ["Scheduled Event"]
        detail = {
            schedule = ["cron(0 * * * ? *)"]
        }
    })
}

# Set rule for eventbridge to get durdduty findings
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "guardduty-findings"
  description = "Trigger Lambda on GuardDuty findings"

  event_pattern = jsonencode({
    source = [
      "aws.guardduty"
    ]
    detail-type = [
      "GuardDuty Finding"
    ]
  })
}

# Add lambda to eventbridge target
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "GuardDutyLambda"
  arn       = aws_lambda_function.SecurityIncidentHandler.arn
}

# Allow eventbridge to invoke lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.SecurityIncidentHandler.function_name
  principal     = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.guardduty_findings.arn
}


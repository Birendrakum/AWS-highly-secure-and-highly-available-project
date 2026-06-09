# Get caller identity
data "aws_caller_identity" "current" {}

# Extract caller account id
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

# Get sns arn
data "aws_sns_topic" "sns_existing" {
  name = "my-topic"  # Replace this by sns name
} 
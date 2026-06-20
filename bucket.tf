# create s3 bucket
resource "aws_s3_bucket" "healt_report_bucket"{
  bucket= "health-report-bucket-${data.aws_caller_identity.current.account_id}"
}

# create s3 bucket for incident reports
resource "aws_s3_bucket" "incident_s3"{
    bucket= "incident-reports-bucket-${data.aws_caller_identity.current.account_id}"
}
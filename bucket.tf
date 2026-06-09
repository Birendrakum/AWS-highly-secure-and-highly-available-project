# create s3 bucket
resource "aws_s3_bucket" "healt_Report_bucket"{
  bucket= "Health-Report-bucket-${data.aws_caller_identity.current.account_id}"
}

# create s3 bucket for incident reports
resource "aws_s3_bucket" "incident_s3"{
    bucket= "Incident-Reports-bucket-${output.account_id}"
}
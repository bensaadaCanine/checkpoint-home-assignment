resource "aws_s3_bucket" "emails_bucket" {
  bucket = "emails-from-queue"

  tags = {
    Name              = "Emails From SQS Queue"
    terraform_managed = true
  }
}


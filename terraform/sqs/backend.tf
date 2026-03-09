terraform {
  backend "s3" {
    bucket         = "bensaada-terraform-state"
    key            = "sqs/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}

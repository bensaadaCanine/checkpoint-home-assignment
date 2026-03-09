terraform {
  backend "s3" {
    bucket         = "bensaada-terraform-state"
    key            = "ecr/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}

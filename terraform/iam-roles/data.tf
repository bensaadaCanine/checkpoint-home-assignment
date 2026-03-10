locals {
  eks_oidc_provider = trimprefix(data.terraform_remote_state.eks.outputs.eks.cluster_oidc_issuer_url, "https://")
}

data "aws_caller_identity" "current" {}

data "http" "alb_controller_policies" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json"
}


data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket  = "bensaada-terraform-state"
    encrypt = true
    key     = "eks/terraform.tfstate"
    region  = "eu-west-1"
  }
}

data "terraform_remote_state" "sqs" {
  backend = "s3"

  config = {
    bucket  = "bensaada-terraform-state"
    encrypt = true
    key     = "sqs/terraform.tfstate"
    region  = "eu-west-1"
  }
}

data "terraform_remote_state" "s3" {
  backend = "s3"

  config = {
    bucket  = "bensaada-terraform-state"
    encrypt = true
    key     = "s3_buckets/terraform.tfstate"
    region  = "eu-west-1"
  }
}


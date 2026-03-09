locals {
  cluster_version = "1.33"
  cluster_name    = data.terraform_remote_state.vpc.outputs.vpc.name
  default_node_tags = {
    Name              = "nodes.${local.cluster_name}"
    ssh_user          = "ec2-user"
    terraform_managed = true
  }

  default_cluster_tags = {
    terraform_managed = true
  }

  default_node_labels = {
    instancegroup     = "nodes"
    terraform_managed = true
  }
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "describe_azs_policy" {
  statement {
    sid = "AllowDescribeAZs"
    actions = [
      "ec2:DescribeAvailabilityZones"
    ]
    resources = [
      "*",
    ]
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket  = "bensaada-terraform-state"
    encrypt = true
    key     = "vpc/terraform.tfstate"
    region  = "eu-west-1"
  }
}

data "terraform_remote_state" "jenkins" {
  backend = "s3"

  config = {
    bucket  = "bensaada-terraform-state"
    encrypt = true
    key     = "jenkins/terraform.tfstate"
    region  = "eu-west-1"
  }
}

locals {
  vpc_cidr     = "10.0.0.0/16"
  cluster_name = "bensaada-home-assignment"
  azs          = data.aws_availability_zones.available.names
  private_subnets = [
    for i, az in local.azs :
    cidrsubnet(local.vpc_cidr, 8, i)
  ]
  public_subnets = [
    for i, az in local.azs :
    cidrsubnet(local.vpc_cidr, 8, i + length(local.azs))
  ]
  tags = {
    terraform_managed = true
  }
}

data "aws_availability_zones" "available" {}

resource "aws_eip" "nat" {
  count  = 3
  domain = "vpc"
  tags = {
    Name              = "${local.cluster_name}-NAT-IP"
    terraform_managed = true
  }
}

# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  name                 = local.cluster_name
  cidr                 = local.vpc_cidr
  azs                  = local.azs
  enable_vpn_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true


  # Public subnets
  public_subnets = local.public_subnets


  # Private subnets
  private_subnets        = local.private_subnets
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
  reuse_nat_ips          = true
  external_nat_ip_ids    = aws_eip.nat.*.id

  tags = local.tags

  public_subnet_tags = {
    "subnet_access"                               = "public"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "subnet_access"                               = "private"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}


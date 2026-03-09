resource "aws_iam_policy" "describe_azs" {
  name = "${local.cluster_name}-describe-azs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowDescribeAZs"
        Effect   = "Allow"
        Action   = "ec2:DescribeAvailabilityZones"
        Resource = "*"
      }
    ]
  })
}

locals {
  iam_role_additional_policies = {
    describeAzs = aws_iam_policy.describe_azs.arn
  }
}

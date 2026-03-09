resource "aws_iam_role" "jenkins_role" {
  name = "jenkins-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "jenkins_iam_policy" {
  name = "jenkins-policies"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = "arn:aws:ssm:eu-west-1:*:parameter/jenkins*"
      },
      {
        Effect : "Allow",
        Action : [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:PutImage"
        ],
        Resource : "*"
      },
      {
        Effect : "Allow",
        Action : [
          "eks:DescribeCluster"
        ],
        Resource : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_iam_policies_attach" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = aws_iam_policy.jenkins_iam_policy.arn
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-instance-profile"
  role = aws_iam_role.jenkins_role.name
}

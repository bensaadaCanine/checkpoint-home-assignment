locals {
  ecr_repos = [
    { name = "email-checker" },
    { name = "queue-checker" },
  ]

}
resource "aws_ecr_repository" "repos" {
  for_each = { for ecr in local.ecr_repos : ecr.name => ecr }

  name = each.key
  tags = {
    terraform_managed = true
  }
}


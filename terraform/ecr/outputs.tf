output "ecr_repos" {
  value = aws_ecr_repository.repos[*]
}

# Usually needs to be retrieved from developers. But since it's a home assignment - we will create the token here

resource "random_password" "validation_token" {
  length  = 25
  special = false
}

resource "aws_ssm_parameter" "validation_token" {
  name  = "/email-checker/validation-token"
  type  = "SecureString"
  value = random_password.validation_token.result
}

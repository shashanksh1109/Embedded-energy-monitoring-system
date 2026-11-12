# =====================================================================
# cognito.tf - User accounts (Amazon Cognito)
#
# Cognito stores users, hashes their passwords, verifies their email and
# issues signed JWTs. Our backend never sees or stores a password; it only
# verifies Cognito's tokens and looks up the user's organization in the
# memberships table.
#
#   User pool  = the user directory (accounts, passwords, email codes)
#   App client = the frontend's identity when it talks to the user pool
# =====================================================================

resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-users"

  # People sign in with their email address instead of a separate username
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = 10
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = false
    temporary_password_validity_days = 7
  }

  # "Forgot password" sends a code to the verified email
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Cognito's built-in email sender. Fine for development, but it is
  # limited to a small number of emails per day; production would use SES.
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Development: allow terraform destroy. Production: set to "ACTIVE".
  deletion_protection = "INACTIVE"

  tags = {
    Name = "${var.project_name}-users"
  }
}

resource "aws_cognito_user_pool_client" "web" {
  name         = "${var.project_name}-web"
  user_pool_id = aws_cognito_user_pool.main.id

  # A browser app cannot keep a secret, so this is a PUBLIC client
  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",       # password proof without sending the password itself
    "ALLOW_USER_PASSWORD_AUTH",  # simple email+password over HTTPS (used for CLI testing and our first frontend)
    "ALLOW_REFRESH_TOKEN_AUTH",  # get new tokens without logging in again
  ]

  # Don't reveal whether an email address has an account
  prevent_user_existence_errors = "ENABLED"

  access_token_validity  = 60   # minutes
  id_token_validity      = 60   # minutes
  refresh_token_validity = 30   # days

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

output "cognito_user_pool_id" {
  description = "Cognito user pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_client_id" {
  description = "Cognito app client ID used by the frontend"
  value       = aws_cognito_user_pool_client.web.id
}

output "cognito_issuer" {
  description = "Token issuer URL; the backend trusts tokens from here only"
  value       = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.main.id}"
}

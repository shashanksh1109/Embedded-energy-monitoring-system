# secrets.tf
# Generates secure random credentials and stores them in AWS Secrets Manager
# Containers fetch secrets at runtime — passwords never appear in code or Git

# ─── RANDOM PASSWORD GENERATION ────────────────────────────────────────
# Terraform generates these once and stores in state file
# They never change unless you explicitly taint and recreate them

resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"  # exclude chars that break DB URLs
}

resource "random_password" "jwt_secret" {
  length  = 64
  special = false  # JWT secrets work better without special chars
}

# ─── DATABASE CREDENTIALS SECRET ───────────────────────────────────────
# Stores DB username + password together as a JSON object
# Spring Boot will read this and parse the fields it needs

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.project_name}/db-credentials"
  description = "PostgreSQL master credentials for the energy management system"

  # How long AWS waits before permanently deleting a secret after destroy
  # 0 = delete immediately (good for dev, lets you recreate with same name)
  recovery_window_in_days = 0

  tags = {
    Name = "${var.project_name}-db-credentials"
  }
}

# The actual secret value — stored as JSON so we can have multiple fields
resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result  # the generated password
    dbname   = var.db_name
    port     = 5432
  })
}

# ─── JWT SECRET ────────────────────────────────────────────────────────
# Spring Boot uses this to sign and verify JWT tokens
# Must be the same value across all backend container instances

resource "aws_secretsmanager_secret" "jwt_secret" {
  name                    = "${var.project_name}/jwt-secret"
  description             = "JWT signing secret for the Spring Boot backend"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.project_name}-jwt-secret"
  }
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = random_password.jwt_secret.result
}

# --- API DATABASE ROLE (ems_api) ----------------------------------------
# The backend connects as ems_api, which is NOT the table owner, so
# PostgreSQL row-level security always applies to it (tenant isolation).
# schema.sql creates the role without a password; the schema-loader Lambda
# sets this generated one after loading the schema.

resource "random_password" "ems_api_password" {
  length  = 32
  special = false   # letters and digits only: safe to embed in ALTER ROLE
}

resource "aws_secretsmanager_secret" "ems_api_credentials" {
  name                    = "${var.project_name}/ems-api-credentials"
  description             = "Credentials of the restricted ems_api database role used by the backend"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.project_name}-ems-api-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "ems_api_credentials" {
  secret_id = aws_secretsmanager_secret.ems_api_credentials.id
  secret_string = jsonencode({
    username = "ems_api"
    password = random_password.ems_api_password.result
  })
}

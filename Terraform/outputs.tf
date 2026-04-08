# outputs.tf
# Exposes important values after terraform apply
# Use: terraform output <name>  to read individual values

# ─── RDS ───────────────────────────────────────────────────────────────

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint — use as DB_HOST in ECS"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.postgres.port
}

# ─── S3 ────────────────────────────────────────────────────────────────

output "frontend_bucket_name" {
  description = "S3 bucket name for React frontend"
  value       = aws_s3_bucket.frontend.id
}

output "frontend_website_url" {
  description = "S3 static website URL for the React frontend"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

output "snapshots_bucket_name" {
  description = "S3 bucket name for DB snapshots"
  value       = aws_s3_bucket.snapshots.id
}

# ─── ECR ───────────────────────────────────────────────────────────────

output "ecr_backend_url" {
  description = "ECR repository URL for Spring Boot backend"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecr_gateway_url" {
  description = "ECR repository URL for Python gateway"
  value       = aws_ecr_repository.gateway.repository_url
}

output "ecr_sensor_url" {
  description = "ECR repository URL for C sensor"
  value       = aws_ecr_repository.sensor.repository_url
}

output "ecr_hvac_url" {
  description = "ECR repository URL for C HVAC controller"
  value       = aws_ecr_repository.hvac.repository_url
}

output "ecr_power_url" {
  description = "ECR repository URL for C power meter"
  value       = aws_ecr_repository.power.repository_url
}

# ─── SECRETS ───────────────────────────────────────────────────────────

output "db_credentials_secret_arn" {
  description = "ARN of DB credentials secret — used in ECS task definition"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "jwt_secret_arn" {
  description = "ARN of JWT secret — used in ECS task definition"
  value       = aws_secretsmanager_secret.jwt_secret.arn
}

# ─── VPC ───────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "VPC ID — used when creating additional security groups"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs — ECS tasks and RDS live here"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs — ALB lives here"
  value       = aws_subnet.public[*].id
}

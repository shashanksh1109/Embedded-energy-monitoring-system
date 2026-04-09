# iam.tf
# IAM roles and policies for ECS
# Two roles: execution role (setup) and task role (runtime)

# ─── TRUST POLICY ──────────────────────────────────────────────────────
# Defines WHO can assume this role
# "ecs-tasks.amazonaws.com" means only ECS task service can use it
# Without this, the role exists but nothing can use it

data "aws_iam_policy_document" "ecs_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]  # sts = Security Token Service, issues temp credentials

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ─── TASK EXECUTION ROLE ───────────────────────────────────────────────
# ECS uses this role to SET UP containers before they start
# Needs: pull from ECR, fetch secrets, write logs

resource "aws_iam_role" "ecs_execution" {
  name               = "${var.project_name}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_trust.json

  tags = {
    Name = "${var.project_name}-ecs-execution-role"
  }
}

# Attach AWS managed policy for ECS task execution
# This policy already includes ECR pull + CloudWatch logs permissions
# AWS maintains it — if new permissions are needed, they update it
resource "aws_iam_role_policy_attachment" "ecs_execution_managed" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Custom policy — adds Secrets Manager access
# The managed policy above does NOT include Secrets Manager
# We need to add it separately
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.project_name}-secrets-access"
  description = "Allows ECS tasks to fetch secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",  # fetch secret value
          "secretsmanager:DescribeSecret"   # read secret metadata
        ]
        Resource = [
          aws_secretsmanager_secret.db_credentials.arn,
          aws_secretsmanager_secret.jwt_secret.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_secrets" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

# ─── TASK ROLE ─────────────────────────────────────────────────────────
# The role the container itself uses WHILE RUNNING
# Your Spring Boot app runs with this identity
# Keep it minimal — only what the app actually needs

resource "aws_iam_role" "ecs_task" {
  name               = "${var.project_name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_trust.json

  tags = {
    Name = "${var.project_name}-ecs-task-role"
  }
}

# Allow containers to write logs to CloudWatch while running
resource "aws_iam_policy" "task_cloudwatch" {
  name        = "${var.project_name}-task-cloudwatch"
  description = "Allows running containers to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_cloudwatch" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.task_cloudwatch.arn
}

# ─── OUTPUTS ───────────────────────────────────────────────────────────
# ECS task definitions need these role ARNs

output "ecs_execution_role_arn" {
  description = "ARN of ECS task execution role"
  value       = aws_iam_role.ecs_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of ECS task role"
  value       = aws_iam_role.ecs_task.arn
}

# lambda.tf
# Lambda function that automatically loads the DB schema after RDS is created

# ─── Upload schema.sql to S3 ───────────────────────────────────────────
resource "aws_s3_object" "schema" {
  bucket = aws_s3_bucket.snapshots.id
  key    = "schema/schema.sql"
  source = "${path.module}/../Database/schema.sql"
  etag   = filemd5("${path.module}/../Database/schema.sql")
}

# ─── Package Lambda with psycopg2 bundled ─────────────────────────────
data "archive_file" "schema_loader" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/package"
  output_path = "${path.module}/lambda/schema_loader.zip"
}

# ─── IAM Role for Lambda ───────────────────────────────────────────────
resource "aws_iam_role" "lambda_schema" {
  name = "${var.project_name}-lambda-schema-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_schema.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "lambda_schema_policy" {
  name = "${var.project_name}-lambda-schema-policy"
  role = aws_iam_role.lambda_schema.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.db_credentials.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.snapshots.arn}/schema/*"
      }
    ]
  })
}

# ─── Lambda Function ───────────────────────────────────────────────────
resource "aws_lambda_function" "schema_loader" {
  filename         = data.archive_file.schema_loader.output_path
  function_name    = "${var.project_name}-schema-loader"
  role             = aws_iam_role.lambda_schema.arn
  handler          = "schema_loader.lambda_handler"
  runtime          = "python3.11"
  timeout          = 60
  source_code_hash = data.archive_file.schema_loader.output_base64sha256

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.rds.id]
  }

  environment {
    variables = {
      DB_SECRET_ARN = aws_secretsmanager_secret.db_credentials.arn
      DB_HOST       = split(":", aws_db_instance.postgres.endpoint)[0]
      DB_NAME       = var.db_name
      SCHEMA_BUCKET = aws_s3_bucket.snapshots.id
      SCHEMA_KEY    = "schema/schema.sql"
    }
  }

  depends_on = [
    aws_db_instance.postgres,
    aws_s3_object.schema,
    aws_iam_role_policy_attachment.lambda_vpc
  ]
}

# ─── Invoke Lambda after creation ──────────────────────────────────────
resource "aws_lambda_invocation" "load_schema" {
  function_name = aws_lambda_function.schema_loader.function_name

  input = jsonencode({
    action = "load_schema"
  })

  triggers = {
    schema_hash = filemd5("${path.module}/../Database/schema.sql")
  }

  depends_on = [aws_lambda_function.schema_loader]
}

output "schema_load_result" {
  description = "Result of schema loading Lambda invocation"
  value       = aws_lambda_invocation.load_schema.result
}

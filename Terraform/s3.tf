# s3.tf
# Two S3 buckets:
# 1. Frontend — serves React app as a static website
# 2. Snapshots — stores DB backups for persistence across destroy/apply

# Get current AWS account ID — used to make bucket name globally unique
data "aws_caller_identity" "current" {}

# ─── FRONTEND BUCKET ───────────────────────────────────────────────────

resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-frontend"
  }
}

# Disable the "block all public access" setting
# AWS blocks all public access by default — we need to allow it for website hosting
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Enable static website hosting
# index.html = served at root URL
# error.html = also index.html so React Router handles 404s client-side
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Allow anyone on the internet to READ files from this bucket
# depends_on ensures public access block is removed before policy is applied
resource "aws_s3_bucket_policy" "frontend" {
  bucket     = aws_s3_bucket.frontend.id
  depends_on = [aws_s3_bucket_public_access_block.frontend]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}

# ─── SNAPSHOTS BUCKET ──────────────────────────────────────────────────
# Stores DB snapshots — private, never public

resource "aws_s3_bucket" "snapshots" {
  bucket = "${var.project_name}-snapshots-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-snapshots"
  }
}

resource "aws_s3_bucket_public_access_block" "snapshots" {
  bucket = aws_s3_bucket.snapshots.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Keep previous versions of snapshot files
# Protects against accidental overwrites
resource "aws_s3_bucket_versioning" "snapshots" {
  bucket = aws_s3_bucket.snapshots.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ─── FRONTEND AUTO-DEPLOY ─────────────────────────────────────────────
# Automatically rebuilds and redeploys frontend with correct ALB URL
# Triggers whenever ALB DNS name changes (e.g. after terraform destroy/apply)
resource "null_resource" "frontend_deploy" {
  triggers = {
    alb_dns    = aws_lb.main.dns_name
    bucket     = aws_s3_bucket.frontend.id
  }

  provisioner "local-exec" {
    command = <<-CMD
      cd ${path.root}/../Frontend
      echo "VITE_API_URL=http://${aws_lb.main.dns_name}/api" > .env.production
      npm run build
      aws s3 sync dist/ s3://${aws_s3_bucket.frontend.id}/ --delete
    CMD
  }

  depends_on = [aws_lb.main, aws_s3_bucket.frontend, aws_s3_bucket_policy.frontend]
}

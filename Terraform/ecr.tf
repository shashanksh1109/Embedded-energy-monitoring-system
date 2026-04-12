# ecr.tf
# Creates private Docker image repositories in AWS
# One repository per service that runs as a container

# ─── BACKEND (Spring Boot) ─────────────────────────────────────────────
resource "aws_ecr_repository" "backend" {
  name                 = "${var.project_name}/backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true  # allows overwriting "latest" tag

  # Scan images for security vulnerabilities on every push
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-backend-ecr"
  }
}

# ─── GATEWAY (Python) ──────────────────────────────────────────────────
resource "aws_ecr_repository" "gateway" {
  name                 = "${var.project_name}/gateway"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-gateway-ecr"
  }
}

# ─── SENSOR (C binary) ─────────────────────────────────────────────────
resource "aws_ecr_repository" "sensor" {
  name                 = "${var.project_name}/sensor"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-sensor-ecr"
  }
}

# ─── HVAC (C binary) ───────────────────────────────────────────────────
resource "aws_ecr_repository" "hvac" {
  name                 = "${var.project_name}/hvac"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-hvac-ecr"
  }
}

# ─── POWER METER (C binary) ────────────────────────────────────────────
resource "aws_ecr_repository" "power" {
  name                 = "${var.project_name}/power"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-power-ecr"
  }
}

# ─── LIFECYCLE POLICIES ────────────────────────────────────────────────
# Automatically delete old images to save storage costs
# Keep only the last 5 images per repository
# Without this, every push accumulates forever

resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "gateway" {
  repository = aws_ecr_repository.gateway.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "sensor" {
  repository = aws_ecr_repository.sensor.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "hvac" {
  repository = aws_ecr_repository.hvac.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "power" {
  repository = aws_ecr_repository.power.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}

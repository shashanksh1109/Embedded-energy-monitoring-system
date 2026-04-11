# alb.tf
# Application Load Balancer — the public front door
# Routes /api/* and /ws/* to ECS backend containers

# ─── SECURITY GROUP: ALB ───────────────────────────────────────────────
# The ALB's firewall — allows HTTP from anywhere on the internet

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB - allows HTTP from internet"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP from anywhere
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound — ALB needs to forward to ECS containers
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# ─── SECURITY GROUP: ECS ───────────────────────────────────────────────
# ECS containers' firewall
# Only accepts traffic from the ALB — nothing from the public internet

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "Security group for ECS tasks - only allows traffic from ALB"
  vpc_id      = aws_vpc.main.id

  # Allow port 8081 ONLY from the ALB security group
  # security_groups reference means: traffic from resources using that SG
  # This is more secure than allowing a CIDR range
  ingress {
    description     = "Backend port from ALB only"
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow port 8080 from ALB — Python gateway
  ingress {
    description     = "Gateway port from ALB only"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow all outbound
  # Containers need to reach: RDS, ECR, Secrets Manager, CloudWatch
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}

# ─── APPLICATION LOAD BALANCER ─────────────────────────────────────────
# Lives in public subnets across both AZs
# internal = false means it faces the internet

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id  # both public subnets

  # If one AZ goes down, ALB keeps serving from the other
  enable_deletion_protection = false  # allow terraform destroy to remove it

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# ─── TARGET GROUP: BACKEND ─────────────────────────────────────────────
# The group of Spring Boot containers ALB forwards /api/* traffic to
# Fargate uses IP target type — containers get their own IPs

resource "aws_lb_target_group" "backend" {
  name        = "${var.project_name}-backend-tg"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"  # required for Fargate

  # Health check — ALB pings this endpoint every 30s
  # If it fails 3 times, container is removed from rotation
  health_check {
    enabled             = true
    path                = "/api/health"  # Spring Boot health endpoint
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2   # 2 successes = healthy
    unhealthy_threshold = 3   # 3 failures = unhealthy
    timeout             = 5   # seconds to wait for response
    interval            = 30  # seconds between checks
    matcher             = "200"  # expect HTTP 200
  }

  tags = {
    Name = "${var.project_name}-backend-tg"
  }
}

# ─── LISTENER ──────────────────────────────────────────────────────────
# Listens on port 80 for incoming HTTP requests
# Default action: forward to backend target group

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # Default action — if no rules match, send to backend
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

# ─── LISTENER RULES ────────────────────────────────────────────────────
# Rules evaluated top to bottom by priority
# First match wins

# Rule 1: /api/* → backend target group
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

# Rule 2: /ws/* → backend target group (WebSocket)
resource "aws_lb_listener_rule" "websocket" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200

  condition {
    path_pattern {
      values = ["/ws/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

# ─── OUTPUTS ───────────────────────────────────────────────────────────

output "alb_dns_name" {
  description = "ALB public DNS name — use this to access the API"
  value       = aws_lb.main.dns_name
}

output "backend_target_group_arn" {
  description = "Backend target group ARN — used in ECS service definition"
  value       = aws_lb_target_group.backend.arn
}

# Allow ECS tasks to talk to each other on port 8080
# Sensor and HVAC/power need to reach the gateway container
resource "aws_security_group_rule" "ecs_internal_8080" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs.id
  source_security_group_id = aws_security_group.ecs.id
  description              = "Allow ECS tasks to communicate internally on port 8080"
}

# ecs.tf
# ECS Fargate cluster, task definitions, and services
# This is where your containers actually run on AWS

# ─── ECS CLUSTER ───────────────────────────────────────────────────────
# Logical grouping for all services
# With Fargate, no EC2 instances to manage

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  # Enable CloudWatch Container Insights
  # Provides CPU, memory, network metrics per service
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# ─── BACKEND TASK DEFINITION ───────────────────────────────────────────
# Describes how to run the Spring Boot container

resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend"
  network_mode             = "awsvpc"    # required for Fargate
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512         # 0.5 vCPU
  memory                   = 1024        # 1 GB
  execution_role_arn       = aws_iam_role.ecs_execution.arn  # pull image, fetch secrets
  task_role_arn            = aws_iam_role.ecs_task.arn       # app runtime permissions

  container_definitions = jsonencode([
    {
      name  = "backend"
      image = "${aws_ecr_repository.backend.repository_url}:latest"

      portMappings = [
        {
          containerPort = 8081
          protocol      = "tcp"
        }
      ]

      # Environment variables injected into the container
      # DB_HOST uses the RDS endpoint we captured in outputs
      # Split at : to remove the port number from the endpoint
      environment = [
        {
          name  = "DB_HOST"
          value = split(":", aws_db_instance.postgres.endpoint)[0]
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "SPRING_PROFILES_ACTIVE"
          value = "docker"
        }
      ]

      # Secrets fetched from Secrets Manager at container startup
      # ECS injects them as environment variables
      # The container sees DB_USER and DB_PASSWORD as normal env vars
      secrets = [
        {
          name      = "DB_USER"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:password::"
        },
        {
          name      = "JWT_SECRET"
          valueFrom = aws_secretsmanager_secret.jwt_secret.arn
        }
      ]

      # Send all container logs to CloudWatch
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}/backend"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      # Health check inside the container
      # ECS uses this to know if the app started successfully
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8081/api/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 120  # give Spring Boot 120s to start before checking
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-backend-task"
  }
}

# ─── GATEWAY TASK DEFINITION ───────────────────────────────────────────

resource "aws_ecs_task_definition" "gateway" {
  family                   = "${var.project_name}-gateway"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "gateway"
      image = "${aws_ecr_repository.gateway.repository_url}:latest"

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "PYTHONUNBUFFERED"
          value = "1"
        },
        {
          name  = "DB_HOST"
          value = split(":", aws_db_instance.postgres.endpoint)[0]
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        }
      ]

      secrets = [
        {
          name      = "DB_USER"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:password::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}/gateway"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-gateway-task"
  }
}

# ─── SENSOR TASK DEFINITION ────────────────────────────────────────────

resource "aws_ecs_task_definition" "sensor" {
  family                   = "${var.project_name}-sensor"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name       = "sensor"
      image      = "${aws_ecr_repository.sensor.repository_url}:latest"
      entryPoint = ["sh", "-c"]
      command    = ["until ./temp_sensor TEMP_A Zone_A 22.0 5; do echo 'Sensor exited, retrying in 15s...'; sleep 15; done"]

      environment = [
        {
          name  = "GATEWAY_HOST"
          value = "gateway.energy.local"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}/sensor"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-sensor-task"
  }
}

# ─── HVAC TASK DEFINITION ──────────────────────────────────────────────

resource "aws_ecs_task_definition" "hvac" {
  family                   = "${var.project_name}-hvac"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name    = "hvac"
      image   = "${aws_ecr_repository.hvac.repository_url}:latest"
      command = ["./hvac_controller", "HVAC_A", "Zone_A", "20.0"]

      environment = [
        {
          name  = "GATEWAY_HOST"
          value = "gateway.energy.local"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}/hvac"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-hvac-task"
  }
}

# ─── POWER TASK DEFINITION ─────────────────────────────────────────────

resource "aws_ecs_task_definition" "power" {
  family                   = "${var.project_name}-power"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name    = "power"
      image   = "${aws_ecr_repository.power.repository_url}:latest"
      command = ["./power_meter", "POWER_A", "Zone_A"]

      environment = [
        {
          name  = "GATEWAY_HOST"
          value = "gateway.energy.local"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}/power"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-power-task"
  }
}

# ─── ECS SERVICES ──────────────────────────────────────────────────────
# Services keep tasks running and connect them to the ALB

# Backend service — connects to ALB target group
resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1       # run 1 container
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false  # private subnet, no public IP
  }

  # Register this service with the ALB target group
  # ALB will send /api/* traffic to this container
  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 8081
  }

  # Wait for ALB to exist before creating service
  depends_on = [aws_lb_listener.http]

  tags = {
    Name = "${var.project_name}-backend-service"
  }
}

# Gateway service — no ALB connection, internal only
resource "aws_ecs_service" "gateway" {
  name            = "${var.project_name}-gateway"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.gateway.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  tags = {
    Name = "${var.project_name}-gateway-service"
  }

  service_registries {
    registry_arn = aws_service_discovery_service.gateway.arn
  }
}

# Sensor service
resource "aws_ecs_service" "sensor" {
  name            = "${var.project_name}-sensor"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.sensor.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  tags = {
    Name = "${var.project_name}-sensor-service"
  }
}

# HVAC service
resource "aws_ecs_service" "hvac" {
  name            = "${var.project_name}-hvac"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.hvac.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  tags = {
    Name = "${var.project_name}-hvac-service"
  }
}

# Power service
resource "aws_ecs_service" "power" {
  name            = "${var.project_name}-power"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.power.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  tags = {
    Name = "${var.project_name}-power-service"
  }
}

# ─── SERVICE DISCOVERY ─────────────────────────────────────────────────
# Allows sensor to find gateway by DNS name: gateway.energy.local

resource "aws_service_discovery_service" "gateway" {
  name = "gateway"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# ─── SERVICE DISCOVERY NAMESPACE ──────────────────────────────────────
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "energy.local"
  description = "Private DNS namespace for ECS service discovery"
  vpc         = aws_vpc.main.id
}

# ─── ROUTE53 VPC ASSOCIATION ──────────────────────────────────────────
# Associates the service discovery hosted zone with the VPC used by ECS tasks
resource "aws_route53_zone_association" "energy_local" {
  zone_id = aws_service_discovery_private_dns_namespace.main.hosted_zone
  vpc_id  = aws_vpc.main.id
}

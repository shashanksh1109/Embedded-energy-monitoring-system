# cloudwatch.tf
# CloudWatch log groups for all ECS services
# Containers write logs here — visible in AWS Console under CloudWatch

locals {
  # List of all services that need log groups
  # Using a local variable avoids repeating the list multiple times
  services = ["backend", "gateway", "sensor", "hvac", "power"]
}

# Create one log group per service
# for_each is like count but uses a set instead of a number
# Each iteration creates a log group named /ecs/energy-management/<service>
resource "aws_cloudwatch_log_group" "ecs" {
  for_each = toset(local.services)

  name              = "/ecs/${var.project_name}/${each.key}"
  retention_in_days = 30  # auto-delete logs older than 30 days

  tags = {
    Name    = "${var.project_name}-${each.key}-logs"
    Service = each.key
  }
}

# ─── CLOUDWATCH ALARM — HIGH CPU ───────────────────────────────────────
# Alerts you if backend CPU stays above 80% for 2 consecutive minutes
# Could indicate a memory leak, traffic spike, or runaway process

resource "aws_cloudwatch_metric_alarm" "backend_cpu_high" {
  alarm_name          = "${var.project_name}-backend-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2       # must breach for 2 consecutive periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60      # check every 60 seconds
  statistic           = "Average"
  threshold           = 80      # alert if CPU > 80%
  alarm_description   = "Backend CPU utilization is above 80%"

  dimensions = {
    ClusterName = "${var.project_name}-cluster"
    ServiceName = "${var.project_name}-backend"
  }

  tags = {
    Name = "${var.project_name}-backend-cpu-alarm"
  }
}

# ─── CLOUDWATCH ALARM — ALB 5XX ERRORS ────────────────────────────────
# Alerts if your backend starts returning server errors
# 5XX = server-side errors (500, 502, 503, 504)
# Threshold: more than 10 errors in 60 seconds

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALB is receiving more than 10 5XX errors per minute"
  treat_missing_data  = "notBreaching"  # no data = no alarm (containers not running)

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = {
    Name = "${var.project_name}-alb-5xx-alarm"
  }
}

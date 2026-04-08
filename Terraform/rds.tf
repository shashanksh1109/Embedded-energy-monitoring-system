# rds.tf
# Managed PostgreSQL database on AWS RDS
# Lives in private subnets — only accessible from ECS containers

# ─── SECURITY GROUP ────────────────────────────────────────────────────
# Firewall rules for the RDS instance
# Only allows PostgreSQL traffic from within the VPC

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS PostgreSQL - only allows VPC internal access"
  vpc_id      = aws_vpc.main.id

  # Allow PostgreSQL from anywhere inside the VPC
  # 10.0.0.0/16 = our entire VPC CIDR
  # This means only resources inside our VPC can connect
  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound traffic
  # RDS needs to send responses back to clients
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# ─── DB SUBNET GROUP ───────────────────────────────────────────────────
# Tells RDS which subnets it can use
# Must span at least 2 AZs — we give it both private subnets

resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-db-subnet-group"
  description = "Private subnets for RDS across two availability zones"
  subnet_ids  = aws_subnet.private[*].id  # [*] means ALL private subnets

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# ─── RDS POSTGRESQL INSTANCE ───────────────────────────────────────────
resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-postgres"  # name shown in AWS console

  # Engine
  engine         = "postgres"
  engine_version = "15"
  instance_class = var.db_instance_class  # db.t3.micro (free tier)

  # Storage
  allocated_storage     = 20    # 20GB minimum for RDS
  max_allocated_storage = 100   # auto-scales up to 100GB if needed
  storage_type          = "gp2" # general purpose SSD

  # Database
  db_name  = var.db_name        # energydb
  username = var.db_username    # energyadmin
  # Password comes from Secrets Manager — not hardcoded here
  password = random_password.db_password.result

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false  # never expose DB to internet

  # Backups
  backup_retention_period = 1     # keep 1 day of automated backups
  backup_window           = "03:00-04:00"  # backup at 3am UTC
  maintenance_window      = "sun:04:00-sun:05:00"

  # Snapshots
  # When terraform destroy runs, take a final snapshot before deleting
  # This is our Option C — data survives destroy
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-final-snapshot"

  # Performance
  # Enhanced monitoring sends OS-level metrics to CloudWatch
  monitoring_interval = 0  # disabled (needs IAM role, we keep it simple)

  # Don't recreate DB if minor version changes
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true

  # Deletion protection — prevents accidental deletion from console
  # We set false because we want terraform destroy to work
  deletion_protection = false

  tags = {
    Name = "${var.project_name}-postgres"
  }
}

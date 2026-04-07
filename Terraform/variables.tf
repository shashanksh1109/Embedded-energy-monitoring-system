# variables.tf
# All input variables for the Energy Management System infrastructure

variable "aws_region" {
  description = "AWS region where all resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for naming and tagging all resources"
  type        = string
  default     = "energy-management"
}

variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
  default     = "dev"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC — defines the IP address range"
  type        = string
  default     = "10.0.0.0/16"  # 65,536 possible addresses
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per availability zone)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]  # 256 addresses each
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per availability zone)"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]  # 256 addresses each
}

# Database Configuration
variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "energydb"
}

variable "db_username" {
  description = "Master username for PostgreSQL"
  type        = string
  default     = "energyadmin"
}

variable "db_instance_class" {
  description = "RDS instance size"
  type        = string
  default     = "db.t3.micro"  # free tier eligible
}

# ECS Configuration
variable "backend_image_tag" {
  description = "Docker image tag for the Spring Boot backend"
  type        = string
  default     = "latest"
}

variable "gateway_image_tag" {
  description = "Docker image tag for the Python gateway"
  type        = string
  default     = "latest"
}

# Alerting
variable "alert_email" {
  description = "Email address for CloudWatch billing and error alerts"
  type        = string
  default     = "shashanksh32@gmail.com"  # change this to your email
}

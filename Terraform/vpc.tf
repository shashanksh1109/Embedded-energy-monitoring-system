# vpc.tf
# Creates the entire network layer:
# VPC → Subnets → Internet Gateway → NAT Gateway → Route Tables

# ─── VPC ───────────────────────────────────────────────────────────────
# The private network that contains everything
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr        # 10.0.0.0/16
  enable_dns_hostnames = true                # allows resources to get DNS names
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# ─── AVAILABILITY ZONES ────────────────────────────────────────────────
# Fetch the list of AZs available in our region dynamically
# So we don't hardcode "us-east-1a" — works in any region
data "aws_availability_zones" "available" {
  state = "available"
}

# ─── PUBLIC SUBNETS ────────────────────────────────────────────────────
# Two public subnets across two AZs — Load Balancer lives here
# count = 2 means Terraform creates this resource twice
# count.index is 0 for first, 1 for second
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  # Resources in public subnet get a public IP automatically
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}

# ─── PRIVATE SUBNETS ───────────────────────────────────────────────────
# Two private subnets — ECS containers and RDS live here
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  # No public IPs — these are private
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
  }
}

# ─── INTERNET GATEWAY ──────────────────────────────────────────────────
# The revolving door — connects the VPC to the internet
# Without this, nothing in the VPC can reach the internet at all
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ─── ELASTIC IP FOR NAT GATEWAY ────────────────────────────────────────
# NAT Gateway needs a fixed public IP address
# Elastic IP = a static IP address you reserve in AWS
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

# ─── NAT GATEWAY ───────────────────────────────────────────────────────
# The turnstile — sits in the PUBLIC subnet
# Private subnet resources route outbound traffic through here
# Lives in public subnet so it can reach the internet via the IGW
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id   # put NAT in first public subnet

  # NAT gateway must be created after the internet gateway
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.project_name}-nat"
  }
}

# ─── ROUTE TABLES ──────────────────────────────────────────────────────
# A route table is like a GPS — tells traffic where to go
# "traffic going to 0.0.0.0/0 (internet)? use this gateway"

# Public route table — sends internet traffic through IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"                    # all internet traffic
    gateway_id = aws_internet_gateway.main.id    # goes through IGW
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Private route table — sends internet traffic through NAT
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"                  # all internet traffic
    nat_gateway_id = aws_nat_gateway.main.id       # goes through NAT (one way)
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# ─── ROUTE TABLE ASSOCIATIONS ──────────────────────────────────────────
# Connect each subnet to its route table
# Without this, subnets don't know which route table to use

# Associate both public subnets with the public route table
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate both private subnets with the private route table
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

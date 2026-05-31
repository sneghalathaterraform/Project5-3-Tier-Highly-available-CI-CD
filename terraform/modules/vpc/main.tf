###############################################################
# Module: Multi-AZ VPC
# 3 tiers: public (ALBs) / private-app (EC2) / private-db (RDS)
###############################################################

locals {
  prefix = "${var.project_name}-${var.environment}"
  tags   = { Project = var.project_name, Environment = var.environment, ManagedBy = "Terraform" }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.tags, { Name = "${local.prefix}-vpc" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.tags, { Name = "${local.prefix}-igw" })
}

# Public subnets – ALBs live here
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags                    = merge(local.tags, { Name = "${local.prefix}-public-${count.index + 1}", Tier = "public" })
}

# Private app subnets – EC2 / Beanstalk instances live here
resource "aws_subnet" "private_app" {
  count             = length(var.private_app_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnets[count.index]
  availability_zone = var.availability_zones[count.index]
  tags              = merge(local.tags, { Name = "${local.prefix}-app-${count.index + 1}", Tier = "app" })
}

# Private DB subnets – RDS lives here, no internet access
resource "aws_subnet" "private_db" {
  count             = length(var.private_db_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_db_subnets[count.index]
  availability_zone = var.availability_zones[count.index]
  tags              = merge(local.tags, { Name = "${local.prefix}-db-${count.index + 1}", Tier = "db" })
}

# NAT Gateways – one per AZ so app instances can reach internet
resource "aws_eip" "nat" {
  count      = length(var.public_subnets)
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
  tags       = merge(local.tags, { Name = "${local.prefix}-nat-eip-${count.index + 1}" })
}

resource "aws_nat_gateway" "nat" {
  count         = length(var.public_subnets)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.igw]
  tags          = merge(local.tags, { Name = "${local.prefix}-nat-${count.index + 1}" })
}

# Public route table – routes to IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(local.tags, { Name = "${local.prefix}-rt-public" })
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private app route tables – one per AZ, routes to NAT
resource "aws_route_table" "private_app" {
  count  = length(var.private_app_subnets)
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }
  tags = merge(local.tags, { Name = "${local.prefix}-rt-app-${count.index + 1}" })
}

resource "aws_route_table_association" "private_app" {
  count          = length(aws_subnet.private_app)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app[count.index].id
}

# Private DB route table – no outbound route (fully isolated)
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.tags, { Name = "${local.prefix}-rt-db" })
}

resource "aws_route_table_association" "private_db" {
  count          = length(aws_subnet.private_db)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db.id
}

###############################################################
# VPC Endpoints – allows private EC2 to use SSM without NAT
###############################################################

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.prefix}-vpc-endpoints-sg"
  description = "Allow HTTPS from private subnets to VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.prefix}-vpc-endpoints-sg" })
}

# SSM endpoint – required for Session Manager
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_app[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  tags                = merge(local.tags, { Name = "${local.prefix}-ssm-endpoint" })
}

# SSM Messages endpoint – required for Session Manager
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_app[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  tags                = merge(local.tags, { Name = "${local.prefix}-ssmmessages-endpoint" })
}

# EC2 Messages endpoint – required for Session Manager
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_app[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  tags                = merge(local.tags, { Name = "${local.prefix}-ec2messages-endpoint" })
}

# S3 endpoint – allows EC2 to pull WAR from S3 without NAT
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private_app[*].id
  tags              = merge(local.tags, { Name = "${local.prefix}-s3-endpoint" })
}
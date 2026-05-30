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

###############################################################
# Module: RDS – MySQL 8.0 Multi-AZ (shared by Part 1 and Part 2)
###############################################################

locals {
  prefix = "${var.project_name}-${var.environment}"
  tags   = { Project = var.project_name, Environment = var.environment, ManagedBy = "Terraform" }
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.prefix}-db-subnet-group"
  subnet_ids = var.db_subnet_ids
  tags       = merge(local.tags, { Name = "${local.prefix}-db-subnet-group" })
}

resource "aws_db_instance" "main" {
  identifier        = "${local.prefix}-mysql"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  multi_az = false
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_sg_id]

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = merge(local.tags, { Name = "${local.prefix}-mysql" })
}



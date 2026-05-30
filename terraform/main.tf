###############################################################
# Project 5 – Final
#
# Part 1: Route 53 → Beanstalk URL → ALB + ASG (PHP 8.4) → RDS
# Part 2: Route 53 → EC2 ALB → ASG (Java 21/Tomcat)      → RDS
###############################################################

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" { region = var.aws_region }

# ── 1. Multi-AZ VPC ──────────────────────────────────────────
module "vpc" {
  source              = "./modules/vpc"
  project_name        = var.project_name
  environment         = var.environment
  vpc_cidr            = "10.0.0.0/16"
  availability_zones  = ["us-east-1a", "us-east-1b"]
  public_subnets      = ["10.0.1.0/24", "10.0.2.0/24"]
  private_app_subnets = ["10.0.10.0/24", "10.0.11.0/24"]
  private_db_subnets  = ["10.0.20.0/24", "10.0.21.0/24"]
}

# ── 2. Security Groups ────────────────────────────────────────
module "security_groups" {
  source       = "./modules/security_groups"
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}

# ── 3. RDS – shared by both parts ────────────────────────────
module "rds" {
  source        = "./modules/rds"
  project_name  = var.project_name
  environment   = var.environment
  db_subnet_ids = module.vpc.private_db_subnet_ids
  db_sg_id      = module.security_groups.rds_sg_id
  db_name       = var.db_name
  db_username   = var.db_username
  db_password   = var.db_password
}

# ── 4. PART 1 – Elastic Beanstalk (PHP 8.4) ──────────────────
# Flow: Route 53 → Beanstalk URL → EB-managed ALB + ASG → RDS
module "beanstalk" {
  source             = "./modules/beanstalk"
  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_app_subnet_ids
  eb_sg_id           = module.security_groups.beanstalk_sg_id
  db_host            = module.rds.endpoint
  db_name            = var.db_name
  db_user            = var.db_username
  db_password        = var.db_password
  aws_region         = var.aws_region
}

# ── 5. PART 2 – EC2 ALB (Java 21 / Tomcat) ───────────────────
# Flow: Route 53 → EC2 ALB → ASG → RDS
module "alb_ec2" {
  source         = "./modules/alb"
  name           = "${var.project_name}-${var.environment}-ec2-alb"
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnet_ids
  alb_sg_id      = module.security_groups.alb_ec2_sg_id
  target_port    = 8080
  health_path    = "/libraryhub/health"
  project_name   = var.project_name
  environment    = var.environment
}

module "ec2_asg" {
  source             = "./modules/ec2_asg"
  project_name       = var.project_name
  environment        = var.environment
  private_subnet_ids = module.vpc.private_app_subnet_ids
  ec2_sg_id          = module.security_groups.ec2_sg_id
  target_group_arn   = module.alb_ec2.target_group_arn
  db_host            = module.rds.endpoint
  db_name            = var.db_name
  db_user            = var.db_username
  db_password        = var.db_password
  aws_region         = var.aws_region
}

# ── 6. Route 53 ───────────────────────────────────────────────
module "route53" {
  source            = "./modules/route53"
  project_name      = var.project_name
  environment       = var.environment
  use_custom_domain = var.use_custom_domain
  domain_name       = var.domain_name
  # Part 1 targets
  eb_cname    = module.beanstalk.eb_cname
  eb_dns_name = module.beanstalk.eb_endpoint_url
  eb_zone_id  = module.beanstalk.eb_hosted_zone_id
  # Part 2 targets
  ec2_alb_dns_name = module.alb_ec2.alb_dns_name
  ec2_alb_zone_id  = module.alb_ec2.alb_zone_id
}

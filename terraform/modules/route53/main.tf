###############################################################
# Module: Route 53
#
# Part 1: health check on EB CNAME (always active)
# Part 2: health check on EC2 ALB  (always active)
#
# Custom domain records (optional – set use_custom_domain = true):
#   app.domain.com → Beanstalk ALB  (Part 1)
#   api.domain.com → EC2 ALB        (Part 2)
###############################################################

# Part 1 – Route 53 health check pointing at Beanstalk URL
resource "aws_route53_health_check" "beanstalk" {
  fqdn              = var.eb_cname
  port              = 80
  type              = "HTTP"
  resource_path     = "/health.php"
  failure_threshold = 3
  request_interval  = 30
  tags              = { Name = "${var.project_name}-${var.environment}-eb-hc" }
}

# Part 2 – Route 53 health check pointing at EC2 ALB
resource "aws_route53_health_check" "ec2_alb" {
  fqdn              = var.ec2_alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/libraryhub/health"
  failure_threshold = 3
  request_interval  = 30
  tags              = { Name = "${var.project_name}-${var.environment}-ec2-hc" }
}

# Optional custom domain alias records
data "aws_route53_zone" "zone" {
  count        = var.use_custom_domain ? 1 : 0
  name         = var.domain_name
  private_zone = false
}

# app.domain.com → Part 1 Beanstalk
resource "aws_route53_record" "part1" {
  count   = var.use_custom_domain ? 1 : 0
  zone_id = data.aws_route53_zone.zone[0].zone_id
  name    = "app.${var.domain_name}"
  type    = "A"
  alias {
    name                   = var.eb_dns_name
    zone_id                = var.eb_zone_id
    evaluate_target_health = true
  }
}

# api.domain.com → Part 2 EC2 ALB
resource "aws_route53_record" "part2" {
  count   = var.use_custom_domain ? 1 : 0
  zone_id = data.aws_route53_zone.zone[0].zone_id
  name    = "api.${var.domain_name}"
  type    = "A"
  alias {
    name                   = var.ec2_alb_dns_name
    zone_id                = var.ec2_alb_zone_id
    evaluate_target_health = true
  }
}

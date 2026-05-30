output "part1_endpoint" { value = var.use_custom_domain ? "app.${var.domain_name}" : var.eb_cname }
output "part2_endpoint" { value = var.use_custom_domain ? "api.${var.domain_name}" : var.ec2_alb_dns_name }

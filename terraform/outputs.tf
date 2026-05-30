output "part1_beanstalk_url" {
  description = "Part 1 – PHP app via Beanstalk"
  value       = "http://${module.beanstalk.eb_endpoint_url}"
}

output "part2_ec2_alb_url" {
  description = "Part 2 – Java/Tomcat app via EC2 ALB"
  value       = "http://${module.alb_ec2.alb_dns_name}/libraryhub/search"
}

output "rds_endpoint" {
  description = "Shared RDS endpoint (used by both parts)"
  value       = module.rds.endpoint
}

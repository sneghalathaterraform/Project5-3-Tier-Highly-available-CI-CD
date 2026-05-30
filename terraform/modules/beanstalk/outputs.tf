output "eb_env_name" { value = aws_elastic_beanstalk_environment.env.name }
output "eb_endpoint_url" { value = aws_elastic_beanstalk_environment.env.endpoint_url }
output "eb_cname" { value = aws_elastic_beanstalk_environment.env.cname }
# Fixed hosted zone ID for ALBs in us-east-1
output "eb_hosted_zone_id" { value = "Z35SXDOTRQ7X7K" }

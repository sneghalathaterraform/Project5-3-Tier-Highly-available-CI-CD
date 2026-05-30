output "alb_ec2_sg_id" { value = aws_security_group.alb_ec2.id }
output "ec2_sg_id" { value = aws_security_group.ec2.id }
output "beanstalk_sg_id" { value = aws_security_group.beanstalk.id }
output "rds_sg_id" { value = aws_security_group.rds.id }

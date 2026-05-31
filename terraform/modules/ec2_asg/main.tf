###############################################################
# Module: EC2 Auto Scaling Group – Part 2 (Java 21 / Tomcat 10)
# Flow: Route 53 → EC2 ALB → this ASG → RDS
###############################################################

locals {
  prefix = "${var.project_name}-${var.environment}"
  tags   = { Project = var.project_name, Environment = var.environment, ManagedBy = "Terraform" }
}

# Latest Amazon Linux 2023 AMI
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM role so EC2 can use SSM and CodeDeploy
resource "aws_iam_role" "ec2" {
  name = "${local.prefix}-ec2-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.prefix}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# User data: installs Java 21 + Tomcat 10 + CodeDeploy agent
resource "aws_launch_template" "main" {
  name_prefix   = "${local.prefix}-lt-"
  image_id      = data.aws_ami.al2023.id
  instance_type = "t3.micro"

  iam_instance_profile { name = aws_iam_instance_profile.ec2.name }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.ec2_sg_id]
  }

  # IMDSv2 enforced
  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  user_data = base64encode(<<-USERDATA
    #!/bin/bash
    set -euo pipefail
    exec > /var/log/user-data.log 2>&1

    # Java 21
    dnf install -y java-21-amazon-corretto-headless
    java -version

    # Tomcat 10
    TOMCAT_VER="10.1.24"
    useradd -r -m -U -d /opt/tomcat -s /bin/false tomcat 2>/dev/null || true
    curl -fsSL "https://archive.apache.org/dist/tomcat/tomcat-10/v$${TOMCAT_VER}/bin/apache-tomcat-$${TOMCAT_VER}.tar.gz" \
      -o /tmp/tomcat.tar.gz
    tar -xzf /tmp/tomcat.tar.gz -C /opt
    ln -sfn /opt/apache-tomcat-$${TOMCAT_VER} /opt/tomcat
    chown -R tomcat:tomcat /opt/tomcat

    # DB env vars
    cat > /etc/profile.d/libraryhub.sh <<EOF
    export DB_HOST="${var.db_host}"
    export DB_NAME="${var.db_name}"
    export DB_USER="${var.db_user}"
    export DB_PASSWORD="${var.db_password}"
    export AWS_REGION="${var.aws_region}"
    EOF
    chmod 644 /etc/profile.d/libraryhub.sh

    # Tomcat systemd service
    cat > /etc/systemd/system/tomcat.service <<EOF
    [Unit]
    Description=Tomcat 10 - LibraryHub Part 2
    After=network.target
    [Service]
    Type=forking
    User=tomcat
    Group=tomcat
    EnvironmentFile=/etc/profile.d/libraryhub.sh
    Environment=JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto
    Environment=CATALINA_HOME=/opt/tomcat
    ExecStart=/opt/tomcat/bin/startup.sh
    ExecStop=/opt/tomcat/bin/shutdown.sh
    Restart=always
    [Install]
    WantedBy=multi-user.target
    EOF

    systemctl daemon-reload
    systemctl enable tomcat
    systemctl start tomcat

    # CodeDeploy agent
    dnf install -y ruby wget
    cd /tmp
    wget -q "https://aws-codedeploy-${var.aws_region}.s3.${var.aws_region}.amazonaws.com/latest/install"
    chmod +x install && ./install auto
    systemctl enable codedeploy-agent
    systemctl start codedeploy-agent

    echo "=== Setup complete ==="
  USERDATA
  )

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.tags, { Name = "${local.prefix}-java-tomcat" })
  }

  lifecycle { create_before_destroy = true }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "main" {
  name                      = "${local.prefix}-asg"
  vpc_zone_identifier       = var.private_subnet_ids
  target_group_arns         = [var.target_group_arn]
  health_check_type         = "EC2"
  health_check_grace_period = 300
  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 1

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.prefix}-java-tomcat"
    propagate_at_launch = true
  }

  lifecycle { create_before_destroy = true }
}

# Scale-out policy (CPU > 70%)
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${local.prefix}-scale-out"
  autoscaling_group_name = aws_autoscaling_group.main.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 120
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.prefix}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]
  dimensions          = { AutoScalingGroupName = aws_autoscaling_group.main.name }
}

# Scale-in policy (CPU < 30%)
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${local.prefix}-scale-in"
  autoscaling_group_name = aws_autoscaling_group.main.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${local.prefix}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 30
  alarm_actions       = [aws_autoscaling_policy.scale_in.arn]
  dimensions          = { AutoScalingGroupName = aws_autoscaling_group.main.name }
}


terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.0"
    }
  }
}

# Security Group for Auto Scaling Group instances
resource "aws_security_group" "asg" {
  name        = "${var.environment}-${var.deployment_color}-asg-sg"
  description = "Security group for ${var.deployment_color} Auto Scaling Group"
  vpc_id      = var.vpc_id

  # Allow HTTP traffic from ALB
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
    description     = "Allow HTTP traffic from ALB"
  }

  # SSH access (for debugging)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Consider restricting this in production
    description = "SSH access"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.environment}-${var.deployment_color}-asg-sg"
  }
}

# IAM Role for Auto Scaling Group instances
resource "aws_iam_role" "asg" {
  name = "${var.environment}-${var.deployment_color}-asg-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.environment}-${var.deployment_color}-asg-role"
  }
}

# IAM Policy for Secrets Manager access
resource "aws_iam_policy" "asg_secrets" {
  name        = "${var.environment}-${var.deployment_color}-asg-secrets-policy"
  description = "Policy to allow ASG instances to access database credentials in Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:/tf-playground/${var.environment}/database/credentials-*"
        ]
      }
    ]
  })

  tags = {
    Name = "${var.environment}-${var.deployment_color}-asg-secrets-policy"
  }
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "asg_secrets" {
  role       = aws_iam_role.asg.name
  policy_arn = aws_iam_policy.asg_secrets.arn
}

# Attach AWS managed policy for EC2 instance core permissions
resource "aws_iam_role_policy_attachment" "asg_ssm" {
  role       = aws_iam_role.asg.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Policy for RDS access
resource "aws_iam_policy" "asg_rds" {
  name        = "${var.environment}-${var.deployment_color}-asg-rds-policy"
  description = "Policy to allow ASG instances to interact with RDS database"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect",
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters"
        ]
        Resource = [
          "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:db:${var.environment}-*",
          "arn:aws:rds-db:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:dbuser:${var.environment}-*/*"
        ]
      }
    ]
  })

  tags = {
    Name = "${var.environment}-${var.deployment_color}-asg-rds-policy"
  }
}

# Attach the RDS policy to the role
resource "aws_iam_role_policy_attachment" "asg_rds" {
  role       = aws_iam_role.asg.name
  policy_arn = aws_iam_policy.asg_rds.arn
}

# Get current region and account ID for the policy
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# IAM Instance Profile
resource "aws_iam_instance_profile" "asg" {
  name = "${var.environment}-${var.deployment_color}-asg-profile"
  role = aws_iam_role.asg.name
}

# Generate SSH key pair
resource "tls_private_key" "asg" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# SSH Key Pair
resource "aws_key_pair" "asg" {
  key_name   = "${var.environment}-${var.deployment_color}-key"
  public_key = tls_private_key.asg.public_key_openssh
}

# User data script for ASG instances
data "template_file" "user_data" {
  template = file("${path.module}/templates/user_data.sh")
  vars = {
    db_host     = var.db_host
    db_name     = var.db_name
    db_user     = var.db_user
    db_password = var.db_password
    deployment_color = var.deployment_color
  }
}

# Launch Template
resource "aws_launch_template" "asg" {
  name_prefix   = "${var.environment}-${var.deployment_color}-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.asg.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.asg.name
  }

  key_name = aws_key_pair.asg.key_name

  user_data = base64encode(data.template_file.user_data.rendered)

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
      volume_type = "gp3"
      encrypted   = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.environment}-${var.deployment_color}-instance"
      Environment = var.environment
      DeploymentColor = var.deployment_color
    }
  }

  tags = {
    Name = "${var.environment}-${var.deployment_color}-launch-template"
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  name                = "${var.environment}-${var.deployment_color}-asg"
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  target_group_arns   = [var.target_group_arn]
  vpc_zone_identifier = var.subnet_ids
  health_check_type   = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.asg.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-${var.deployment_color}-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "DeploymentColor"
    value               = var.deployment_color
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Policy for CPU-based scaling
resource "aws_autoscaling_policy" "cpu_policy" {
  name                   = "${var.environment}-${var.deployment_color}-cpu-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

# CloudWatch Alarm for CPU utilization
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "${var.environment}-${var.deployment_color}-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors EC2 CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.cpu_policy.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
} 
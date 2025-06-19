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

# Security Group for Web Server
resource "aws_security_group" "webserver" {
  name        = "${var.environment}-webserver-sg"
  description = "Security group for web server"
  vpc_id      = var.vpc_id

  # Allow HTTP traffic on port 8080
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic on port 8080"
  }

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Consider restricting this to your IP range
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
    Name = "${var.environment}-webserver-sg"
  }
}

# IAM Role for Web Server
resource "aws_iam_role" "webserver" {
  name = "${var.environment}-webserver-role"

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
    Name = "${var.environment}-webserver-role"
  }
}

# IAM Policy for Secrets Manager access
resource "aws_iam_policy" "webserver_secrets" {
  name        = "${var.environment}-webserver-secrets-policy"
  description = "Policy to allow webserver to access database credentials in Secrets Manager"

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
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = [
          "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"
        ]
      }
    ]
  })

  tags = {
    Name = "${var.environment}-webserver-secrets-policy"
  }
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "webserver_secrets" {
  role       = aws_iam_role.webserver.name
  policy_arn = aws_iam_policy.webserver_secrets.arn
}

# Attach AWS managed policy for EC2 instance core permissions
resource "aws_iam_role_policy_attachment" "webserver_ssm" {
  role       = aws_iam_role.webserver.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Policy for RDS access
resource "aws_iam_policy" "webserver_rds" {
  name        = "${var.environment}-webserver-rds-policy"
  description = "Policy to allow webserver to interact with RDS database"

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
    Name = "${var.environment}-webserver-rds-policy"
  }
}

# Attach the RDS policy to the role
resource "aws_iam_role_policy_attachment" "webserver_rds" {
  role       = aws_iam_role.webserver.name
  policy_arn = aws_iam_policy.webserver_rds.arn
}

# Get current region and account ID for the policy
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# IAM Instance Profile
resource "aws_iam_instance_profile" "webserver" {
  name = "${var.environment}-webserver-profile"
  role = aws_iam_role.webserver.name
}

# Generate SSH key pair
resource "tls_private_key" "webserver" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# SSH Key Pair
resource "aws_key_pair" "webserver" {
  key_name   = var.key_name
  public_key = tls_private_key.webserver.public_key_openssh
}

# User data script for web server setup
data "template_file" "user_data" {
  template = file("${path.module}/templates/user_data.sh")
  vars = {
    db_host     = var.db_host
    db_name     = var.db_name
    db_user     = var.db_user
    db_password = var.db_password
  }
}

# EC2 Instance
resource "aws_instance" "webserver" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnets[0] # Place in first public subnet
  vpc_security_group_ids = [aws_security_group.webserver.id]
  iam_instance_profile   = aws_iam_instance_profile.webserver.name
  key_name               = var.key_name
  user_data              = data.template_file.user_data.rendered

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.environment}-webserver"
  }

  # Ensure proper shutdown
  lifecycle {
    create_before_destroy = true
    replace_triggered_by = [
      aws_iam_role.webserver,
      aws_iam_policy.webserver_secrets,
      aws_iam_policy.webserver_rds,
      aws_iam_role_policy_attachment.webserver_secrets,
      aws_iam_role_policy_attachment.webserver_ssm,
      aws_iam_role_policy_attachment.webserver_rds
    ]
  }
}

# Elastic IP for Web Server
resource "aws_eip" "webserver" {
  instance = aws_instance.webserver.id
  domain   = "vpc"

  tags = {
    Name = "${var.environment}-webserver-eip"
  }
} 
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
    cidr_blocks = ["0.0.0.0/0"]  # Consider restricting this to your IP range
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

# IAM Instance Profile
resource "aws_iam_instance_profile" "webserver" {
  name = "${var.environment}-webserver-profile"
  role = aws_iam_role.webserver.name
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
  subnet_id              = var.public_subnets[0]  # Place in first public subnet
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
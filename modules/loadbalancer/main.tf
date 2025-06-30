terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Security Group for Application Load Balancer
resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  # Allow HTTP traffic from internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from internet"
  }

  # Allow HTTPS traffic from internet (for future SSL)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic from internet"
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
    Name = "${var.environment}-alb-sg"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets

  enable_deletion_protection = false

  tags = {
    Name = "${var.environment}-alb"
  }
}

# Target Group for Blue Environment
resource "aws_lb_target_group" "blue" {
  name     = "${var.environment}-blue-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health/simple"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.environment}-blue-tg"
  }
}

# Target Group for Green Environment
resource "aws_lb_target_group" "green" {
  name     = "${var.environment}-green-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health/simple"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.environment}-green-tg"
  }
}

# HTTP Listener (Port 80)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  tags = {
    Name = "${var.environment}-alb-http-listener"
  }
}

# Listener Rule for Blue Environment (default)
resource "aws_lb_listener_rule" "blue" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  tags = {
    Name = "${var.environment}-blue-rule"
  }
}

# Listener Rule for Green Environment (for failover testing)
resource "aws_lb_listener_rule" "green" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }

  condition {
    path_pattern {
      values = ["/green*", "/green/*"]
    }
  }

  tags = {
    Name = "${var.environment}-green-rule"
  }
}

# HTTPS Listener (Port 443) - for future SSL implementation
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  tags = {
    Name = "${var.environment}-alb-https-listener"
  }

  # Only create if certificate is provided
  count = var.certificate_arn != null ? 1 : 0
} 
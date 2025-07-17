terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Security group is now managed by the networking module

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnets

  enable_deletion_protection = false

  tags = {
    Name = "${var.environment}-alb"
  }
}

# WAF Web ACL Association
resource "aws_wafv2_web_acl_association" "alb" {
  count = var.waf_web_acl_arn != null ? 1 : 0

  resource_arn = aws_lb.main.arn
  web_acl_arn  = var.waf_web_acl_arn
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
    interval            = 60
    matcher             = "200"
    path                = "/health/simple"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 30
    unhealthy_threshold = 5
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
    interval            = 60
    matcher             = "200"
    path                = "/health/simple"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 30
    unhealthy_threshold = 5
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

# Note: Listener rules removed for proper blue-green deployment
# Traffic switching is handled by modifying the listener's default action

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
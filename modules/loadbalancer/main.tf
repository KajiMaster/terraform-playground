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

# ALB to ECS tasks egress rule (when ECS is enabled)
resource "aws_security_group_rule" "alb_ecs_egress" {
  count = var.enable_ecs ? 1 : 0
  
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = var.ecs_tasks_security_group_id
  security_group_id        = var.security_group_id
  description              = "Allow outbound traffic to ECS tasks on port 8080"
}

# ALB to EKS pods egress rule (when EKS is enabled)
resource "aws_security_group_rule" "alb_eks_egress" {
  count = var.enable_eks ? 1 : 0
  
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = var.eks_pods_security_group_id
  security_group_id        = var.security_group_id
  description              = "Allow outbound traffic to EKS pods on port 8080"
}

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
  name        = var.target_type == "ip" ? "${var.environment}-blue-tg-ecs" : "${var.environment}-blue-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = var.target_type

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
    Name = var.target_type == "ip" ? "${var.environment}-blue-tg-ecs" : "${var.environment}-blue-tg"
  }
}

# Target Group for Green Environment
resource "aws_lb_target_group" "green" {
  name        = var.target_type == "ip" ? "${var.environment}-green-tg-ecs" : "${var.environment}-green-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = var.target_type

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
    Name = var.target_type == "ip" ? "${var.environment}-green-tg-ecs" : "${var.environment}-green-tg"
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

# Listener Rule for Green Environment (for blue-green deployments)
resource "aws_lb_listener_rule" "green" {
  count        = var.create_green_listener_rule ? 1 : 0
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

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
    Name = "${var.environment}-green-listener-rule"
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
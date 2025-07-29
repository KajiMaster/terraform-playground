# Universal Environment Outputs Template
# This file can be used across all environments (dev, staging, production)
# Environment-specific values are handled via variables

# Load Balancer Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.loadbalancer.alb_dns_name
}

output "alb_url" {
  description = "URL to access the application via ALB"
  value       = module.loadbalancer.alb_url
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.loadbalancer.alb_zone_id
}

# SSH Key Outputs
output "ssh_key_name" {
  description = "Name of the SSH key pair"
  value       = aws_key_pair.environment_key.key_name
}

output "ssh_private_key" {
  description = "Private key for SSH access (sensitive)"
  value       = data.aws_secretsmanager_secret_version.ssh_private.secret_string
  sensitive   = true
}

output "ssh_public_key" {
  description = "Public key content"
  value       = data.aws_secretsmanager_secret_version.ssh_public.secret_string
  sensitive   = true
}

# Blue Auto Scaling Group Outputs
output "blue_asg_id" {
  description = "ID of the blue Auto Scaling Group"
  value       = var.disable_asg ? null : module.blue_asg[0].asg_id
}

output "blue_asg_name" {
  description = "Name of the blue Auto Scaling Group"
  value       = var.disable_asg ? null : module.blue_asg[0].asg_name
}

output "blue_target_group_arn" {
  description = "ARN of the blue target group"
  value       = module.loadbalancer.blue_target_group_arn
}

# Green Auto Scaling Group Outputs
output "green_asg_id" {
  description = "ID of the green Auto Scaling Group"
  value       = var.disable_asg ? null : module.green_asg[0].asg_id
}

output "green_asg_name" {
  description = "Name of the green Auto Scaling Group"
  value       = var.disable_asg ? null : module.green_asg[0].asg_name
}

output "green_target_group_arn" {
  description = "ARN of the green target group"
  value       = module.loadbalancer.green_target_group_arn
}

# ECS Outputs
output "ecs_tasks_security_group_id" {
  description = "ID of the ECS tasks security group"
  value       = var.enable_ecs ? module.ecs[0].ecs_tasks_security_group_id : null
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = var.enable_ecs ? module.ecs[0].ecr_repository_url : null
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = var.enable_ecs ? module.ecs[0].ecs_cluster_name : null
}

output "blue_ecs_service_name" {
  description = "Name of the blue ECS service"
  value       = var.enable_ecs ? module.ecs[0].blue_service_name : null
}

output "green_ecs_service_name" {
  description = "Name of the green ECS service"
  value       = var.enable_ecs ? module.ecs[0].green_service_name : null
}

# Database Outputs
output "database_endpoint" {
  description = "The connection endpoint of the RDS instance"
  value       = module.database.db_instance_endpoint
}

output "database_name" {
  description = "The database name"
  value       = module.database.db_instance_name
}

output "database_port" {
  description = "The database port"
  value       = module.database.db_instance_port
}

# Network Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.networking.private_subnet_ids
}

# SSM Outputs
output "ssm_automation_name" {
  description = "Name of the SSM automation for database initialization"
  value       = var.disable_asg ? null : module.ssm[0].ssm_automation_name
}

output "ssm_automation_role_arn" {
  description = "ARN of the SSM automation role"
  value       = var.disable_asg ? null : module.ssm[0].ssm_automation_role_arn
}

# Database Outputs
output "db_username" {
  description = "Database username"
  value       = "tfplayground_user"
}

output "db_password" {
  description = "Database password (sensitive)"
  value       = data.aws_secretsmanager_secret_version.db_password.secret_string
  sensitive   = true
}

output "db_secret_name" {
  description = "Name of the centralized database credentials secret"
  value       = data.aws_secretsmanager_secret.db_password.name
}

output "db_secret_arn" {
  description = "ARN of the centralized database credentials secret"
  value       = data.aws_secretsmanager_secret.db_password.arn
}

# Application URLs
output "application_url" {
  description = "URL to access the web application via ALB"
  value       = module.loadbalancer.alb_url
}

output "health_check_url" {
  description = "URL to access the health check endpoint"
  value       = "${module.loadbalancer.alb_url}/health"
}

output "deployment_validation_url" {
  description = "URL to access the deployment validation endpoint"
  value       = "${module.loadbalancer.alb_url}/deployment/validate"
}

# Environment Summary
output "environment_summary" {
  description = "Summary of the blue-green deployment environment"
  value = {
    environment       = var.environment
    region            = var.aws_region
    vpc_id            = module.networking.vpc_id
    alb_dns_name      = module.loadbalancer.alb_dns_name
    application_url   = module.loadbalancer.alb_url
    blue_asg_name     = var.disable_asg ? null : module.blue_asg[0].asg_name
    green_asg_name    = var.disable_asg ? null : module.green_asg[0].asg_name
    database_endpoint = module.database.db_instance_endpoint
    ssh_key_name      = aws_key_pair.environment_key.key_name
  }
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = module.loadbalancer.http_listener_arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener (if created)"
  value       = module.loadbalancer.https_listener_arn
}

output "deployment_timestamp" {
  description = "Timestamp of last deployment"
  value       = "Deployed via GitFlow CI/CD - ${title(var.environment)} Environment"
}

# Logging outputs
output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = module.logging.dashboard_url
}

output "application_log_group_name" {
  description = "Application log group name"
  value       = module.logging.application_log_group_name
}

output "system_log_group_name" {
  description = "System log group name"
  value       = module.logging.system_log_group_name
}

output "high_error_rate_alarm_arn" {
  description = "High error rate alarm ARN"
  value       = module.logging.high_error_rate_alarm_arn
}

output "slow_response_time_alarm_arn" {
  description = "Slow response time alarm ARN"
  value       = module.logging.slow_response_time_alarm_arn
}

# Global Log Group ARNs (from shared remote state)
output "global_application_log_group_arn" {
  description = "Application log group ARN from global environment"
  value       = data.terraform_remote_state.global.outputs.application_log_group_arns[var.environment]
}

output "global_system_log_group_arn" {
  description = "System log group ARN from global environment"
  value       = data.terraform_remote_state.global.outputs.system_log_group_arns[var.environment]
}

output "global_alarm_log_group_arn" {
  description = "Alarm log group ARN from global environment"
  value       = data.terraform_remote_state.global.outputs.alarm_log_group_arns[var.environment]
}

# All global log group ARNs for this environment
output "global_log_group_arns" {
  description = "Map of global log group ARNs"
  value = {
    application = data.terraform_remote_state.global.outputs.application_log_group_arns[var.environment]
    system      = data.terraform_remote_state.global.outputs.system_log_group_arns[var.environment]
    alarm       = data.terraform_remote_state.global.outputs.alarm_log_group_arns[var.environment]
  }
}










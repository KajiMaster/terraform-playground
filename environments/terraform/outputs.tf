# Universal Environment Outputs Template
# This file can be used across all environments (dev, staging, production)
# Environment-specific values are handled via variables

# Load Balancer Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = (var.enable_asg || var.enable_ecs) ? module.loadbalancer[0].alb_dns_name : null
}

output "alb_url" {
  description = "URL to access the application via ALB"
  value       = (var.enable_asg || var.enable_ecs) ? module.loadbalancer[0].alb_url : null
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = (var.enable_asg || var.enable_ecs) ? module.loadbalancer[0].alb_zone_id : null
}

# SSH Key Outputs
output "ssh_key_name" {
  description = "Name of the SSH key pair"
  value       = length(aws_key_pair.environment_key) > 0 ? aws_key_pair.environment_key[0].key_name : null
}

output "ssh_private_key" {
  description = "Private key for SSH access (sensitive)"
  value       = data.aws_secretsmanager_secret_version.ssh_private.secret_string
  sensitive   = true
}

output "ssh_public_key" {
  description = "Public key content"
  value       = length(data.aws_secretsmanager_secret_version.ssh_public) > 0 ? data.aws_secretsmanager_secret_version.ssh_public[0].secret_string : null
  sensitive   = true
}

# Blue Auto Scaling Group Outputs
output "blue_asg_id" {
  description = "ID of the blue Auto Scaling Group"
  value       = var.enable_asg ? module.blue_asg[0].asg_id : null
}

output "blue_asg_name" {
  description = "Name of the blue Auto Scaling Group"
  value       = var.enable_asg ? module.blue_asg[0].asg_name : null
}

output "blue_target_group_arn" {
  description = "ARN of the blue target group"
  value       = (var.enable_asg || var.enable_ecs) ? module.loadbalancer[0].blue_target_group_arn : null
}

# Green Auto Scaling Group Outputs
output "green_asg_id" {
  description = "ID of the green Auto Scaling Group"
  value       = var.enable_asg ? module.green_asg[0].asg_id : null
}

output "green_asg_name" {
  description = "Name of the green Auto Scaling Group"
  value       = var.enable_asg ? module.green_asg[0].asg_name : null
}

output "green_target_group_arn" {
  description = "ARN of the green target group"
  value       = (var.enable_asg || var.enable_ecs) ? module.loadbalancer[0].green_target_group_arn : null
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

# EKS Outputs
output "eks_cluster_id" {
  description = "ID of the EKS cluster"
  value       = var.enable_eks ? module.eks[0].cluster_id : null
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = var.enable_eks ? module.eks[0].cluster_name : null
}

output "eks_cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = var.enable_eks ? module.eks[0].cluster_endpoint : null
}

output "eks_node_group_id" {
  description = "ID of the EKS node group"
  value       = var.enable_eks ? module.eks[0].node_group_id : null
}

output "eks_node_group_status" {
  description = "Status of the EKS node group"
  value       = var.enable_eks ? module.eks[0].node_group_status : null
}

# Database Outputs (conditional on enable_rds)
output "database_endpoint" {
  description = "The connection endpoint of the RDS instance"
  value       = var.enable_rds ? module.database[0].db_instance_endpoint : null
}

output "database_name" {
  description = "The database name"
  value       = var.enable_rds ? module.database[0].db_instance_name : null
}

output "database_port" {
  description = "The database port"
  value       = var.enable_rds ? module.database[0].db_instance_port : null
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
  value       = var.enable_asg ? module.ssm[0].ssm_automation_name : null
}

output "ssm_automation_role_arn" {
  description = "ARN of the SSM automation role"
  value       = var.enable_asg ? module.ssm[0].ssm_automation_role_arn : null
}

# Database Outputs
output "db_username" {
  description = "Database username"
  value       = "tfplayground_user"
}

output "db_password" {
  description = "Database password from Parameter Store (sensitive)"
  value       = var.enable_rds ? data.aws_ssm_parameter.db_password[0].value : null
  sensitive   = true
}

output "db_secret_name" {
  description = "Name of the centralized database credentials parameter"
  value       = var.enable_rds ? "/tf-playground/all/db-password" : null
}

output "db_secret_arn" {
  description = "ARN of the centralized database credentials parameter"
  value       = var.enable_rds ? data.aws_ssm_parameter.db_password[0].arn : null
}

# Application URLs
output "application_url" {
  description = "URL to access the application"
  value = (var.enable_asg || var.enable_ecs) ? module.loadbalancer[0].alb_url : (
    var.enable_eks ? "http://${kubernetes_service.flask_app[0].status[0].load_balancer[0].ingress[0].hostname}:8080" : "No load balancer configured"
  )
}

output "health_check_url" {
  description = "URL for health checks"
  value = (var.enable_asg || var.enable_ecs) ? "${module.loadbalancer[0].alb_url}/health" : (
    var.enable_eks ? "http://${kubernetes_service.flask_app[0].status[0].load_balancer[0].ingress[0].hostname}:8080/health/simple" : "No load balancer configured"
  )
}

output "deployment_validation_url" {
  description = "URL for deployment validation"
  value = (var.enable_asg || var.enable_ecs) ? "${module.loadbalancer[0].alb_url}/deployment/validate" : (
    var.enable_eks ? "http://${kubernetes_service.flask_app[0].status[0].load_balancer[0].ingress[0].hostname}:8080/health/simple" : "No load balancer configured"
  )
}

# EKS LoadBalancer Service Outputs
output "eks_loadbalancer_url" {
  description = "URL of the EKS LoadBalancer service"
  value = var.enable_eks ? "http://${kubernetes_service.flask_app[0].status[0].load_balancer[0].ingress[0].hostname}:8080" : null
}

output "eks_health_check_url" {
  description = "Health check URL for EKS LoadBalancer service"
  value = var.enable_eks ? "http://${kubernetes_service.flask_app[0].status[0].load_balancer[0].ingress[0].hostname}:8080/health/simple" : null
}

# Environment Summary
output "environment_summary" {
  description = "Summary of the blue-green deployment environment"
  value = {
    environment       = var.environment
    region            = var.aws_region
    vpc_id            = module.networking.vpc_id
    alb_dns_name      = (var.enable_asg || var.enable_ecs) ? module.loadbalancer[0].alb_dns_name : null
    application_url   = (var.enable_asg || var.enable_ecs) ? module.loadbalancer[0].alb_url : (
      var.enable_eks ? "http://${kubernetes_service.flask_app[0].status[0].load_balancer[0].ingress[0].hostname}:8080" : "No load balancer configured"
    )
    blue_asg_name     = var.enable_asg ? module.blue_asg[0].asg_name : null
    green_asg_name    = var.enable_asg ? module.green_asg[0].asg_name : null
    database_endpoint = var.enable_rds ? module.database[0].db_instance_endpoint : "serverless-architecture"
    ssh_key_name      = length(aws_key_pair.environment_key) > 0 ? aws_key_pair.environment_key[0].key_name : null
  }
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = (var.enable_asg || var.enable_ecs) ? module.loadbalancer[0].http_listener_arn : null
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener (if created)"
  value       = (var.enable_asg || var.enable_ecs) ? module.loadbalancer[0].https_listener_arn : null
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










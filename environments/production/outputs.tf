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
  value       = module.ssh_keys.key_name
}

output "ssh_private_key" {
  description = "Private key for SSH access (sensitive)"
  value       = module.ssh_keys.private_key
  sensitive   = true
}

output "ssh_public_key" {
  description = "Public key content"
  value       = module.ssh_keys.public_key
}

# Blue Auto Scaling Group Outputs
output "blue_asg_id" {
  description = "ID of the blue Auto Scaling Group"
  value       = module.blue_asg.asg_id
}

output "blue_asg_name" {
  description = "Name of the blue Auto Scaling Group"
  value       = module.blue_asg.asg_name
}

output "blue_target_group_arn" {
  description = "ARN of the blue target group"
  value       = module.loadbalancer.blue_target_group_arn
}

# Green Auto Scaling Group Outputs
output "green_asg_id" {
  description = "ID of the green Auto Scaling Group"
  value       = module.green_asg.asg_id
}

output "green_asg_name" {
  description = "Name of the green Auto Scaling Group"
  value       = module.green_asg.asg_name
}

output "green_target_group_arn" {
  description = "ARN of the green target group"
  value       = module.loadbalancer.green_target_group_arn
}

# SSH Keys for debugging
output "blue_asg_private_key" {
  description = "Private key for SSH access to blue ASG instances"
  value       = module.blue_asg.private_key
  sensitive   = true
}

output "green_asg_private_key" {
  description = "Private key for SSH access to green ASG instances"
  value       = module.green_asg.private_key
  sensitive   = true
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
  value       = module.ssm.ssm_automation_name
}

output "ssm_automation_role_arn" {
  description = "ARN of the SSM automation role"
  value       = module.ssm.ssm_automation_role_arn
}

# Secrets Outputs
output "random_suffix" {
  description = "Random suffix used for resource names"
  value       = module.secrets.random_suffix
}

output "secret_name" {
  description = "Name of the database credentials secret"
  value       = module.secrets.secret_name
}

output "secret_arn" {
  description = "ARN of the database credentials secret"
  value       = module.secrets.secret_arn
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
  description = "Summary of the production blue-green deployment environment"
  value = {
    environment       = var.environment
    region            = var.aws_region
    vpc_id            = module.networking.vpc_id
    alb_dns_name      = module.loadbalancer.alb_dns_name
    application_url   = module.loadbalancer.alb_url
    blue_asg_name     = module.blue_asg.asg_name
    green_asg_name    = module.green_asg.asg_name
    database_endpoint = module.database.db_instance_endpoint
    ssh_key_name      = module.ssh_keys.key_name
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
  value       = "Deployed via GitFlow CI/CD - Production Environment"
} 
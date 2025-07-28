# ECS Integration for Staging Environment
# This file can be conditionally included to add ECS alongside existing ASG

# Variable to control ECS deployment
variable "enable_ecs" {
  description = "Enable ECS Fargate deployment alongside ASG"
  type        = bool
  default     = false
}

# ECS Module (conditionally created)
module "ecs" {
  count  = var.enable_ecs ? 1 : 0
  source = "../../modules/ecs"

  environment = var.environment
  aws_region  = var.aws_region

  # Use global ECR repository instead of creating local one
  ecr_repository_url = data.terraform_remote_state.global.outputs.ecr_repository_url

  # Network Configuration
  vpc_id                     = module.networking.vpc_id
  private_subnets            = module.networking.private_subnet_ids
  alb_security_group_id      = module.networking.alb_security_group_id
  database_security_group_id = module.networking.database_security_group_id

  # Load Balancer Integration (uses existing ALB)
  blue_target_group_arn  = module.loadbalancer.blue_target_group_arn
  green_target_group_arn = module.loadbalancer.green_target_group_arn

  # Database Configuration
  db_host = module.database.db_instance_address
  db_user = "tfplayground_user"
  db_password = data.aws_secretsmanager_secret_version.db_password.secret_string
  db_name = var.db_name

  # Logging (uses existing CloudWatch log groups)
  application_log_group_name = module.logging.application_log_group_name

  # Resource Configuration (start with minimal resources)
  task_cpu    = 512   # 0.5 vCPU
  task_memory = 1024  # 1 GB

  # Service Configuration (use variables)
  blue_desired_count  = var.blue_ecs_desired_count
  green_desired_count = var.green_ecs_desired_count
}

# Outputs for ECS (only when enabled)
output "ecr_repository_url" {
  description = "ECR repository URL for container images (from global environment)"
  value       = var.enable_ecs ? data.terraform_remote_state.global.outputs.ecr_repository_url : null
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = var.enable_ecs ? module.ecs[0].ecs_cluster_name : null
}

output "ecs_tasks_security_group_id" {
  description = "ECS tasks security group ID"
  value       = var.enable_ecs ? module.ecs[0].ecs_tasks_security_group_id : null
}

output "blue_ecs_service_name" {
  description = "Blue ECS service name"
  value       = var.enable_ecs ? module.ecs[0].blue_service_name : null
}

output "green_ecs_service_name" {
  description = "Green ECS service name"
  value       = var.enable_ecs ? module.ecs[0].green_service_name : null
}

output "container_image_url" {
  description = "Full container image URL for deployment"
  value       = var.enable_ecs ? "${data.terraform_remote_state.global.outputs.ecr_repository_url}:latest" : null
}

output "ecs_environment_summary" {
  description = "ECS environment summary"
  value       = var.enable_ecs ? module.ecs[0].ecs_environment_summary : null
} 
# ECS Integration for Workspace Environment
# This file adds ECS deployment using the global ECR repository

# ECS Module (conditionally created)
module "ecs" {
  count  = var.enable_ecs ? 1 : 0
  source = "../../modules/ecs"

  environment = local.environment
  aws_region  = var.aws_region

  # Use global ECR repository instead of creating local one
  ecr_repository_url = data.terraform_remote_state.global.outputs.ecr_repository_url

  # Network Configuration
  vpc_id                = module.networking.vpc_id
  private_subnets       = module.networking.private_subnet_ids
  alb_security_group_id = module.networking.alb_security_group_id

  # Load Balancer Integration (uses existing ALB)
  blue_target_group_arn  = var.enable_ecs ? module.loadbalancer[0].blue_target_group_arn : null
  green_target_group_arn = var.enable_ecs ? module.loadbalancer[0].green_target_group_arn : null

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

# Note: ECS tasks security group ID is now defined in main.tf locals block 
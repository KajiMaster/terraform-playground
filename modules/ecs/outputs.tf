# ECR Repository Outputs (using external ECR from global environment)
output "ecr_repository_url" {
  description = "URL of the ECR repository (from global environment)"
  value       = var.ecr_repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository (from global environment)"
  value       = "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${split("/", var.ecr_repository_url)[1]}"
}

output "ecr_repository_name" {
  description = "Name of the ECR repository (from global environment)"
  value       = split("/", var.ecr_repository_url)[1]
}

# ECS Cluster Outputs
output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

# IAM Role Outputs
output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

# Security Group Outputs
output "ecs_tasks_security_group_id" {
  description = "ID of the ECS tasks security group"
  value       = aws_security_group.ecs_tasks.id
}

# Task Definition Outputs
output "blue_task_definition_arn" {
  description = "ARN of the blue task definition"
  value       = aws_ecs_task_definition.blue.arn
}

output "blue_task_definition_family" {
  description = "Family of the blue task definition"
  value       = aws_ecs_task_definition.blue.family
}

output "green_task_definition_arn" {
  description = "ARN of the green task definition"
  value       = aws_ecs_task_definition.green.arn
}

output "green_task_definition_family" {
  description = "Family of the green task definition"
  value       = aws_ecs_task_definition.green.family
}

# ECS Service Outputs
output "blue_service_id" {
  description = "ID of the blue ECS service"
  value       = aws_ecs_service.blue.id
}

output "blue_service_name" {
  description = "Name of the blue ECS service"
  value       = aws_ecs_service.blue.name
}

output "blue_service_arn" {
  description = "ARN of the blue ECS service"
  value       = aws_ecs_service.blue.id
}

output "green_service_id" {
  description = "ID of the green ECS service"
  value       = aws_ecs_service.green.id
}

output "green_service_name" {
  description = "Name of the green ECS service"
  value       = aws_ecs_service.green.name
}

output "green_service_arn" {
  description = "ARN of the green ECS service"
  value       = aws_ecs_service.green.id
}

# Container Image Outputs
output "container_image_url" {
  description = "Full URL for the container image"
  value       = "${var.ecr_repository_url}:latest"
}

# Environment Summary
output "ecs_environment_summary" {
  description = "Summary of the ECS environment"
  value = {
    environment           = var.environment
    ecr_repository_url    = var.ecr_repository_url
    ecs_cluster_name      = aws_ecs_cluster.main.name
    blue_service_name     = aws_ecs_service.blue.name
    green_service_name    = aws_ecs_service.green.name
    task_cpu              = var.task_cpu
    task_memory           = var.task_memory
    blue_desired_count    = var.blue_desired_count
    green_desired_count   = var.green_desired_count
  }
} 
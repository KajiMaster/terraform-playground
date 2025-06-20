output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "webserver_instance_id" {
  description = "ID of the web server instance"
  value       = module.webserver.instance_id
}

output "webserver_public_ip" {
  description = "Public IP address of the web server"
  value       = module.webserver.public_ip
}

output "database_endpoint" {
  description = "RDS database endpoint"
  value       = module.database.db_instance_endpoint
}

output "database_name" {
  description = "RDS database name"
  value       = module.database.db_instance_name
}

output "ssm_automation_document_name" {
  description = "Name of the SSM automation document"
  value       = module.ssm.ssm_automation_name
}

output "ssm_automation_role_arn" {
  description = "ARN of the SSM automation role"
  value       = module.ssm.ssm_automation_role_arn
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role for staging"
  value       = module.oidc.github_actions_role_arn
}

output "random_suffix" {
  description = "Random suffix used for resource names"
  value       = module.secrets.random_suffix
} 
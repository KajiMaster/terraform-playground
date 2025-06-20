output "webserver_public_ip" {
  description = "Public IP address of the web server"
  value       = module.webserver.public_ip
}

output "webserver_instance_id" {
  description = "ID of the EC2 instance"
  value       = module.webserver.instance_id
}

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

output "ssm_automation_name" {
  description = "Name of the SSM automation for database initialization"
  value       = module.ssm.ssm_automation_name
}

output "ssm_automation_role_arn" {
  description = "ARN of the SSM automation role"
  value       = module.ssm.ssm_automation_role_arn
} 
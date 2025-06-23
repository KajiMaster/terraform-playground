# Network outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

# Web server outputs
output "webserver_public_ip" {
  description = "Public IP of the web server"
  value       = module.webserver.public_ip
}

output "webserver_instance_id" {
  description = "Instance ID of the web server"
  value       = module.webserver.instance_id
}

output "webserver_security_group_id" {
  description = "Security group ID of the web server"
  value       = module.webserver.security_group_id
}

# Database outputs
output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.db_instance_address
}

output "database_port" {
  description = "RDS instance port"
  value       = module.database.db_instance_port
}

output "database_name" {
  description = "Database name"
  value       = var.db_name
}

# Secrets outputs
output "secret_arn" {
  description = "ARN of the database credentials secret"
  value       = module.secrets.secret_arn
}

output "secret_name" {
  description = "Name of the database credentials secret"
  value       = module.secrets.secret_name
}

# SSM outputs
output "ssm_parameter_prefix" {
  description = "SSM parameter prefix for database bootstrapping"
  value       = module.ssm.parameter_prefix
}

# Application URL
output "application_url" {
  description = "URL to access the web application"
  value       = "http://${module.webserver.public_ip}"
}

# Environment summary
output "environment_summary" {
  description = "Summary of the production environment"
  value = {
    environment = var.environment
    region      = var.aws_region
    vpc_id      = module.networking.vpc_id
    webserver_ip = module.webserver.public_ip
    database_endpoint = module.database.db_instance_address
    application_url = "http://${module.webserver.public_ip}"
  }
} 
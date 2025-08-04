output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = aws_db_instance.database.address
}

output "db_instance_endpoint" {
  description = "The connection endpoint of the RDS instance"
  value       = aws_db_instance.database.endpoint
}

output "db_instance_name" {
  description = "The database name"
  value       = aws_db_instance.database.db_name
}

output "db_instance_port" {
  description = "The database port"
  value       = aws_db_instance.database.port
}

output "db_security_group_id" {
  description = "The security group ID of the RDS instance"
  value       = var.security_group_id
}

# Environment pattern outputs
output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.database.name
}

output "db_subnet_placement" {
  description = "Where RDS is placed based on environment pattern"
  value       = var.enable_private_subnets ? "private-subnets" : "public-subnets"
}

output "environment_pattern" {
  description = "Current environment pattern for RDS"
  value       = var.enable_private_subnets ? "enterprise" : "dev"
} 
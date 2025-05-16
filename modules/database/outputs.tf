output "db_instance_id" {
  description = "The ID of the RDS instance"
  value       = aws_db_instance.database.id
}

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

output "db_instance_username" {
  description = "The master username for the database"
  value       = aws_db_instance.database.username
  sensitive   = true
}

output "db_security_group_id" {
  description = "The security group ID of the RDS instance"
  value       = aws_security_group.database.id
} 
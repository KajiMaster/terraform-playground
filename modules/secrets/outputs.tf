output "db_username" {
  description = "Database username"
  value       = var.create_resources ? "tfplayground_user" : null
}



output "secret_name" {
  description = "Name of the database secret"
  value       = var.create_resources ? aws_secretsmanager_secret.database[0].name : null
}

output "secret_arn" {
  description = "ARN of the database secret"
  value       = var.create_resources ? aws_secretsmanager_secret.database[0].arn : null
}

output "ssh_key_name" {
  description = "Name of the SSH key pair"
  value       = var.ssh_public_key_secret_name != null ? aws_key_pair.managed[0].key_name : null
}

output "ssh_private_key" {
  description = "SSH private key content"
  value       = var.ssh_private_key_secret_name != null ? data.aws_secretsmanager_secret_version.ssh_private[0].secret_string : null
  sensitive   = true
}

output "ssh_public_key" {
  description = "SSH public key content"
  value       = var.ssh_public_key_secret_name != null ? data.aws_secretsmanager_secret_version.ssh_public[0].secret_string : null
}

output "db_password" {
  description = "Database password from Secrets Manager"
  value       = var.db_password_secret_name != null ? data.aws_secretsmanager_secret_version.db_password[0].secret_string : null
  sensitive   = true
}

output "db_credentials" {
  description = "The database credentials from the secret"
  value       = var.create_resources ? jsondecode(aws_secretsmanager_secret_version.database[0].secret_string) : null
  sensitive   = true
}

output "parameter_prefix" {
  description = "The prefix used for Parameter Store parameters"
  value       = "/tf-playground/${var.environment}"
}

output "random_suffix" {
  description = "The random suffix used for resource names"
  value       = var.create_resources ? random_id.secret_suffix[0].hex : null
} 
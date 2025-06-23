output "db_username" {
  description = "The database username"
  value       = var.create_resources ? "tfplayground_user" : jsondecode(data.aws_secretsmanager_secret_version.db_credentials[0].secret_string)["username"]
}

output "db_password" {
  description = "The database password"
  value       = var.create_resources ? random_password.db_password[0].result : jsondecode(data.aws_secretsmanager_secret_version.db_credentials[0].secret_string)["password"]
  sensitive   = true
}

output "secret_arn" {
  description = "The ARN of the secret"
  value       = var.create_resources ? aws_secretsmanager_secret.db_credentials[0].arn : data.aws_secretsmanager_secret.db_credentials[0].arn
}

output "secret_name" {
  description = "The name of the secret"
  value       = var.create_resources ? aws_secretsmanager_secret.db_credentials[0].name : data.aws_secretsmanager_secret.db_credentials[0].name
}

output "db_credentials" {
  description = "The database credentials from the secret"
  value       = var.create_resources ? jsondecode(aws_secretsmanager_secret_version.db_credentials[0].secret_string) : jsondecode(data.aws_secretsmanager_secret_version.db_credentials[0].secret_string)
  sensitive   = true
}

output "parameter_prefix" {
  description = "The prefix used for Parameter Store parameters"
  value       = "/tf-playground/${var.environment}"
}

output "random_suffix" {
  description = "The random suffix used for resource names"
  value       = var.create_resources ? random_string.suffix[0].result : null
} 
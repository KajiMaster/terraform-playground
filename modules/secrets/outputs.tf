output "kms_key_id" {
  description = "The ID of the KMS key used for encryption"
  value       = var.create_resources ? aws_kms_key.secrets[0].key_id : data.aws_kms_key.secrets[0].key_id
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for encryption"
  value       = var.create_resources ? aws_kms_key.secrets[0].arn : data.aws_kms_key.secrets[0].arn
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
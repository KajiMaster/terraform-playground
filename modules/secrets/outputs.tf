output "kms_key_id" {
  description = "The ID of the KMS key used for encryption"
  value       = data.aws_kms_key.secrets.key_id
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for encryption"
  value       = data.aws_kms_key.secrets.arn
}

output "secret_arn" {
  description = "The ARN of the secret"
  value       = data.aws_secretsmanager_secret.db_credentials.arn
}

output "secret_name" {
  description = "The name of the secret"
  value       = data.aws_secretsmanager_secret.db_credentials.name
}

output "db_credentials" {
  description = "The database credentials from the secret"
  value       = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
  sensitive   = true
}

output "parameter_prefix" {
  description = "The prefix used for Parameter Store parameters"
  value       = "/tf-playground/${var.environment}"
} 
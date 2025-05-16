output "kms_key_id" {
  description = "The ID of the KMS key used for encryption"
  value       = aws_kms_key.secrets.key_id
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for encryption"
  value       = aws_kms_key.secrets.arn
}

output "parameter_prefix" {
  description = "The prefix used for Parameter Store parameters"
  value       = "/tf-playground/${var.environment}"
} 
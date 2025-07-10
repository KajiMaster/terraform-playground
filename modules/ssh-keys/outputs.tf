output "key_name" {
  description = "Name of the AWS key pair"
  value       = aws_key_pair.environment_key.key_name
}

output "key_id" {
  description = "ID of the AWS key pair"
  value       = aws_key_pair.environment_key.key_pair_id
}

output "private_key" {
  description = "Private key content from centralized secret (sensitive)"
  value       = data.aws_secretsmanager_secret_version.ssh_private.secret_string
  sensitive   = true
}

output "public_key" {
  description = "Public key content from centralized secret"
  value       = data.aws_secretsmanager_secret_version.ssh_public.secret_string
}

output "ssh_private_secret_arn" {
  description = "ARN of the SSH private key secret"
  value       = data.aws_secretsmanager_secret.ssh_private.arn
}

output "ssh_public_secret_arn" {
  description = "ARN of the SSH public key secret"
  value       = data.aws_secretsmanager_secret.ssh_public.arn
} 
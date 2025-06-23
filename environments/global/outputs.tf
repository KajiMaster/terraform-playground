output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = module.oidc.oidc_provider_arn
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = module.oidc.github_actions_role_arn
}

output "github_actions_role_name" {
  description = "Name of the GitHub Actions IAM role"
  value       = module.oidc.github_actions_role_name
} 
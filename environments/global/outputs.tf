# OIDC Provider outputs
output "github_actions_role_arn" {
  description = "GitHub Actions IAM role ARN"
  value       = module.oidc.github_actions_role_arn
}

output "github_actions_role_name" {
  description = "GitHub Actions IAM role name"
  value       = module.oidc.github_actions_role_name
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = module.oidc.oidc_provider_arn
}

# Log Groups outputs
output "application_log_groups" {
  description = "Map of environment to application log group names"
  value       = module.log_groups.application_log_groups
}

output "application_log_group_arns" {
  description = "Map of environment to application log group ARNs"
  value       = module.log_groups.application_log_group_arns
}

output "system_log_groups" {
  description = "Map of environment to system log group names"
  value       = module.log_groups.system_log_groups
}

output "system_log_group_arns" {
  description = "Map of environment to system log group ARNs"
  value       = module.log_groups.system_log_group_arns
}

output "alarm_log_groups" {
  description = "Map of environment to alarm log group names"
  value       = module.log_groups.alarm_log_groups
}

output "alarm_log_group_arns" {
  description = "Map of environment to alarm log group ARNs"
  value       = module.log_groups.alarm_log_group_arns
}

# WAF outputs
output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = module.waf.waf_web_acl_arn
}

output "waf_web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = module.waf.waf_web_acl_id
}

output "waf_enabled" {
  description = "Whether WAF is enabled"
  value       = module.waf.waf_enabled
}

output "waf_logging_enabled" {
  description = "Whether WAF logging is enabled"
  value       = module.waf.waf_logging_enabled
}

output "waf_log_bucket_name" {
  description = "Name of the S3 bucket storing WAF logs"
  value       = module.waf.waf_log_bucket_name
}

# ECR Repository outputs
output "ecr_repository_url" {
  description = "The URL of the global ECR repository"
  value       = module.ecr.repository_url
}

output "ecr_repository_name" {
  description = "The name of the global ECR repository"
  value       = module.ecr.repository_name
}

output "ecr_repository_arn" {
  description = "The ARN of the global ECR repository"
  value       = module.ecr.repository_arn
}

output "ecr_registry_id" {
  description = "The registry ID where the global ECR repository was created"
  value       = module.ecr.registry_id
} 
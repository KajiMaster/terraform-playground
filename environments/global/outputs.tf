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
output "application_log_group_name" {
  description = "Global application log group name"
  value       = module.log_groups.application_log_group_name
}

output "application_log_group_arn" {
  description = "Global application log group ARN"
  value       = module.log_groups.application_log_group_arn
}

output "system_log_group_name" {
  description = "Global system log group name"
  value       = module.log_groups.system_log_group_name
}

output "system_log_group_arn" {
  description = "Global system log group ARN"
  value       = module.log_groups.system_log_group_arn
}

output "alarm_log_group_name" {
  description = "Global alarm log group name"
  value       = module.log_groups.alarm_log_group_name
}

output "alarm_log_group_arn" {
  description = "Global alarm log group ARN"
  value       = module.log_groups.alarm_log_group_arn
} 
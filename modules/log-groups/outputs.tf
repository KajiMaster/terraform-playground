output "application_log_groups" {
  description = "Map of environment to application log group names"
  value       = { for env, lg in aws_cloudwatch_log_group.application_logs : env => lg.name }
}

output "application_log_group_arns" {
  description = "Map of environment to application log group ARNs"
  value       = { for env, lg in aws_cloudwatch_log_group.application_logs : env => lg.arn }
}

output "system_log_groups" {
  description = "Map of environment to system log group names"
  value       = { for env, lg in aws_cloudwatch_log_group.system_logs : env => lg.name }
}

output "system_log_group_arns" {
  description = "Map of environment to system log group ARNs"
  value       = { for env, lg in aws_cloudwatch_log_group.system_logs : env => lg.arn }
}

output "alarm_log_groups" {
  description = "Map of environment to alarm log group names"
  value       = { for env, lg in aws_cloudwatch_log_group.alarm_logs : env => lg.name }
}

output "alarm_log_group_arns" {
  description = "Map of environment to alarm log group ARNs"
  value       = { for env, lg in aws_cloudwatch_log_group.alarm_logs : env => lg.arn }
} 
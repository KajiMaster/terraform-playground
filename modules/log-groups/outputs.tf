output "application_log_group_name" {
  description = "Application log group name"
  value       = aws_cloudwatch_log_group.application_logs.name
}

output "application_log_group_arn" {
  description = "Application log group ARN"
  value       = aws_cloudwatch_log_group.application_logs.arn
}

output "system_log_group_name" {
  description = "System log group name"
  value       = aws_cloudwatch_log_group.system_logs.name
}

output "system_log_group_arn" {
  description = "System log group ARN"
  value       = aws_cloudwatch_log_group.system_logs.arn
}

output "alarm_log_group_name" {
  description = "Alarm log group name"
  value       = aws_cloudwatch_log_group.alarm_logs.name
}

output "alarm_log_group_arn" {
  description = "Alarm log group ARN"
  value       = aws_cloudwatch_log_group.alarm_logs.arn
} 
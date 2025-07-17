output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=tf-playground-${var.environment}"
}

output "application_log_group_name" {
  description = "Application log group name (from global)"
  value       = var.application_log_group_name
}

output "system_log_group_name" {
  description = "System log group name (from global)"
  value       = var.system_log_group_name
}

output "high_error_rate_alarm_arn" {
  description = "High error rate alarm ARN"
  value       = aws_cloudwatch_metric_alarm.high_error_rate.arn
}

output "slow_response_time_alarm_arn" {
  description = "Slow response time alarm ARN"
  value       = aws_cloudwatch_metric_alarm.slow_response_time.arn
} 
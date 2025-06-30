output "budget_arn" {
  description = "ARN of the AWS Budget"
  value       = aws_budgets_budget.daily_lab_budget.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for cost alerts"
  value       = aws_sns_topic.cost_alerts.arn
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function for after-hours checking"
  value       = aws_lambda_function.after_hours_check.arn
}

output "cloudwatch_alarm_arn" {
  description = "ARN of the CloudWatch alarm for after-hours usage"
  value       = aws_cloudwatch_metric_alarm.after_hours_usage.arn
} 
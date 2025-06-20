output "ssm_automation_name" {
  description = "Name of the SSM automation document for database initialization"
  value       = aws_ssm_document.database_automation.name
}

output "ssm_automation_arn" {
  description = "ARN of the SSM automation document for database initialization"
  value       = aws_ssm_document.database_automation.arn
}

output "ssm_automation_role_arn" {
  description = "ARN of the SSM automation role"
  value       = aws_iam_role.ssm_automation.arn
} 
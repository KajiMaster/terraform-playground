output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = var.enable_waf ? aws_wafv2_web_acl.main[0].arn : null
}

output "waf_web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = var.enable_waf ? aws_wafv2_web_acl.main[0].id : null
}

output "waf_web_acl_name" {
  description = "Name of the WAF Web ACL"
  value       = var.enable_waf ? aws_wafv2_web_acl.main[0].name : null
}

output "waf_enabled" {
  description = "Whether WAF is enabled"
  value       = var.enable_waf
}

output "waf_logging_enabled" {
  description = "Whether WAF logging is enabled"
  value       = var.enable_waf && var.enable_logging
}

output "waf_log_bucket_name" {
  description = "Name of the S3 bucket storing WAF logs"
  value       = aws_s3_bucket.waf_logs.bucket
} 
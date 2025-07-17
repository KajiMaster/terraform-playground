terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# WAF Web ACL
resource "aws_wafv2_web_acl" "main" {
  count = var.enable_waf ? 1 : 0

  name        = "tf-playground-waf"
  description = "WAF for Terraform Playground demo"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # Common attack patterns rule
  rule {
    name     = "CommonAttackPatterns"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonAttackPatterns"
      sampled_requests_enabled   = true
    }
  }

  # SQL injection protection rule
  rule {
    name     = "SQLInjection"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLInjection"
      sampled_requests_enabled   = true
    }
  }

  # Rate limiting rule
  rule {
    name     = "RateLimit"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = true
    }
  }

  # IP reputation rule (if enabled)
  rule {
    name     = "IPReputation"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "IPReputation"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WAFWebACL"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "tf-playground-waf"
    Environment = "global"
    Project     = "tf-playground"
    ManagedBy   = "terraform"
    Purpose     = "centralized-waf"
  }
}

# WAF Logging Configuration
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  count = var.enable_waf && var.enable_logging ? 1 : 0

  log_destination_configs = [aws_kinesis_firehose_delivery_stream.waf_logs[0].arn]
  resource_arn            = aws_wafv2_web_acl.main[0].arn
}

# Kinesis Firehose for WAF logs - Conditional (only when WAF is enabled)
resource "aws_kinesis_firehose_delivery_stream" "waf_logs" {
  count = var.enable_waf && var.enable_logging ? 1 : 0

  name        = "aws-waf-logs-tf-playground"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role[0].arn
    bucket_arn = aws_s3_bucket.waf_logs.arn
    prefix     = "waf-logs/"
  }

  tags = {
    Name        = "waf-logs-firehose"
    Environment = "global"
    Project     = "tf-playground"
    ManagedBy   = "terraform"
    Purpose     = "conditional-waf-logs"
  }
}

# S3 bucket for WAF logs - Persistent (doesn't delete when WAF is disabled)
resource "aws_s3_bucket" "waf_logs" {
  bucket = "tf-playground-waf-logs-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "waf-logs-bucket"
    Environment = "global"
    Project     = "tf-playground"
    ManagedBy   = "terraform"
    Purpose     = "persistent-waf-logs"
  }
}

# Random string for unique bucket name - Persistent
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 bucket lifecycle for log retention - Persistent
resource "aws_s3_bucket_lifecycle_configuration" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id

  rule {
    id     = "log_retention"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = var.log_retention_days
    }
  }
}

# IAM role for Firehose - Conditional (only when WAF is enabled)
resource "aws_iam_role" "firehose_role" {
  count = var.enable_waf && var.enable_logging ? 1 : 0

  name = "firehose-waf-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "firehose-waf-logs-role"
    Environment = "global"
    Project     = "tf-playground"
    ManagedBy   = "terraform"
    Purpose     = "conditional-waf-logs"
  }
}

# IAM policy for Firehose - Conditional (only when WAF is enabled)
resource "aws_iam_role_policy" "firehose_policy" {
  count = var.enable_waf && var.enable_logging ? 1 : 0

  name = "firehose-waf-logs-policy"
  role = aws_iam_role.firehose_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.waf_logs.arn,
          "${aws_s3_bucket.waf_logs.arn}/*"
        ]
      }
    ]
  })
} 
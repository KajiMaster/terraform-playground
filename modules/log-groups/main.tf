terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Global CloudWatch Log Groups - Environment-specific paths
resource "aws_cloudwatch_log_group" "application_logs" {
  for_each = toset(var.environments)

  name              = "/aws/application/tf-playground/${each.key}"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = each.key
    Project     = "tf-playground"
    Purpose     = "application-logs"
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "system_logs" {
  for_each = toset(var.environments)

  name              = "/aws/ec2/tf-playground/${each.key}"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = each.key
    Project     = "tf-playground"
    Purpose     = "system-logs"
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "alarm_logs" {
  for_each = toset(var.environments)

  name              = "/aws/cloudwatch/alarms/tf-playground/${each.key}"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = each.key
    Project     = "tf-playground"
    Purpose     = "alarm-logs"
    ManagedBy   = "terraform"
  }
} 
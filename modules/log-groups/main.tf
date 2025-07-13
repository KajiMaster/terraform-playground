terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Global CloudWatch Log Groups - Shared across environments
resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "/aws/application/tf-playground"
  retention_in_days = var.log_retention_days
  force_destroy     = true

  tags = {
    Environment = "global"
    Project     = "tf-playground"
    Purpose     = "shared-application-logs"
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "system_logs" {
  name              = "/aws/ec2/tf-playground"
  retention_in_days = var.log_retention_days
  force_destroy     = true

  tags = {
    Environment = "global"
    Project     = "tf-playground"
    Purpose     = "shared-system-logs"
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "alarm_logs" {
  name              = "/aws/cloudwatch/alarms/tf-playground"
  retention_in_days = var.log_retention_days
  force_destroy     = true

  tags = {
    Environment = "global"
    Project     = "tf-playground"
    Purpose     = "shared-alarm-logs"
    ManagedBy   = "terraform"
  }
} 
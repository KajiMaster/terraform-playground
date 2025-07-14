terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# CloudWatch Log Groups - Now managed globally
# These are referenced from the global environment
locals {
  application_log_group_name = var.application_log_group_name
  system_log_group_name      = var.system_log_group_name
  alarm_log_group_name       = var.alarm_log_group_name
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "tf-playground-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_identifier],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Application Load Balancer Metrics"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          query  = "SOURCE '/aws/application/${var.environment}'\n| fields @timestamp, @message\n| sort @timestamp desc\n| limit 20"
          region = var.aws_region
          title  = "Recent Application Logs"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          query  = "SOURCE '/aws/application/${var.environment}'\n| filter @message like /ERROR/\n| fields @timestamp, @message\n| sort @timestamp desc\n| limit 10"
          region = var.aws_region
          title  = "Recent Errors"
        }
      }
    ]
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "high-error-rate-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "High 5XX error rate detected"
  alarm_actions       = var.alarm_actions

  dimensions = {
    LoadBalancer = var.alb_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "slow_response_time" {
  alarm_name          = "slow-response-time-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "2"
  alarm_description   = "Slow response time detected"
  alarm_actions       = var.alarm_actions

  dimensions = {
    LoadBalancer = var.alb_identifier
  }
}

 
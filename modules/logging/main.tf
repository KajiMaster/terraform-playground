terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "/aws/application/${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Project     = "tf-playground"
    AutoDelete  = "true"
    DemoPeriod  = "24h"
  }
}

resource "aws_cloudwatch_log_group" "system_logs" {
  name              = "/aws/ec2/${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Project     = "tf-playground"
    AutoDelete  = "true"
    DemoPeriod  = "24h"
  }
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
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "app/${var.alb_name}/99e60c16fce11186"],
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
          query   = "SOURCE '/aws/application/${var.environment}'\n| fields @timestamp, @message\n| sort @timestamp desc\n| limit 20"
          region  = var.aws_region
          title   = "Recent Application Logs"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          query   = "SOURCE '/aws/application/${var.environment}'\n| filter @message like /ERROR/\n| fields @timestamp, @message\n| sort @timestamp desc\n| limit 10"
          region  = var.aws_region
          title   = "Recent Errors"
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
    LoadBalancer = "app/${var.alb_name}/99e60c16fce11186"
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
    LoadBalancer = "app/${var.alb_name}/99e60c16fce11186"
  }
}

# Demo Cleanup Lambda (Optional - for cost control)
resource "aws_lambda_function" "cleanup_logs" {
  count = var.enable_cleanup ? 1 : 0
  
  filename         = data.archive_file.cleanup_zip[0].output_path
  function_name    = "cleanup-logs-${var.environment}"
  role            = aws_iam_role.cleanup_lambda[0].arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  environment {
    variables = {
      LOG_GROUP_NAMES = jsonencode([
        aws_cloudwatch_log_group.application_logs.name,
        aws_cloudwatch_log_group.system_logs.name
      ])
    }
  }

  tags = {
    Environment = var.environment
    Project     = "tf-playground"
    Purpose     = "demo-cleanup"
  }
}

data "archive_file" "cleanup_zip" {
  count = var.enable_cleanup ? 1 : 0
  
  type        = "zip"
  output_path = "${path.module}/cleanup-lambda.zip"
  source {
    content = <<EOF
import boto3
import json
import os
from datetime import datetime, timedelta

def handler(event, context):
    logs_client = boto3.client('logs')
    log_group_names = json.loads(os.environ['LOG_GROUP_NAMES'])
    
    cutoff_time = datetime.now() - timedelta(days=1)
    
    for log_group in log_group_names:
        try:
            # Delete log streams older than 1 day
            response = logs_client.describe_log_streams(
                logGroupName=log_group,
                orderBy='LastEventTime',
                descending=True
            )
            
            for stream in response['logStreams']:
                if 'lastEventTimestamp' in stream:
                    stream_time = datetime.fromtimestamp(stream['lastEventTimestamp'] / 1000)
                    if stream_time < cutoff_time:
                        logs_client.delete_log_stream(
                            logGroupName=log_group,
                            logStreamName=stream['logStreamName']
                        )
                        print(f"Deleted stream: {stream['logStreamName']}")
        except Exception as e:
            print(f"Error cleaning up {log_group}: {e}")
    
    return {"statusCode": 200, "body": "Cleanup completed"}
EOF
    filename = "index.py"
  }
}

resource "aws_iam_role" "cleanup_lambda" {
  count = var.enable_cleanup ? 1 : 0
  
  name = "cleanup-logs-lambda-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cleanup_lambda" {
  count = var.enable_cleanup ? 1 : 0
  
  name = "cleanup-logs-policy-${var.environment}"
  role = aws_iam_role.cleanup_lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogStreams",
          "logs:DeleteLogStream"
        ]
        Resource = [
          aws_cloudwatch_log_group.application_logs.arn,
          aws_cloudwatch_log_group.system_logs.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
} 
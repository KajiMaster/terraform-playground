terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS Budget for daily spending limit
resource "aws_budgets_budget" "daily_lab_budget" {
  name              = "tf-playground-daily-lab-budget"
  budget_type       = "COST"
  time_unit         = "DAILY"
  limit_amount      = var.daily_budget_limit
  limit_unit        = "USD"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.alert_email_addresses
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 200
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.alert_email_addresses
  }

  cost_filters = {
    TagKeyValue = "Project$$tf-playground"
  }

  tags = {
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
    Name        = "tf-playground-daily-budget"
  }
}

# CloudWatch Alarm for after-hours usage
resource "aws_cloudwatch_metric_alarm" "after_hours_usage" {
  alarm_name          = "tf-playground-after-hours-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "300" # 5 minutes
  statistic           = "Maximum"
  threshold           = "0.01" # Alert if spending more than $0.01
  alarm_description   = "Alert when lab environments are running outside business hours"
  alarm_actions       = [aws_sns_topic.cost_alerts.arn]

  dimensions = {
    Currency = "USD"
  }

  tags = {
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
    Name        = "tf-playground-after-hours-alarm"
  }
}

# SNS Topic for cost alerts
resource "aws_sns_topic" "cost_alerts" {
  name = "tf-playground-cost-alerts"

  tags = {
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
    Name        = "tf-playground-cost-alerts"
  }
}

# SNS Topic Subscription for email notifications
resource "aws_sns_topic_subscription" "cost_alerts_email" {
  count     = length(var.alert_email_addresses)
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email_addresses[count.index]
}

# CloudWatch Event Rule to check for running resources after hours
resource "aws_cloudwatch_event_rule" "after_hours_check" {
  name                = "tf-playground-after-hours-check"
  description         = "Check for running lab resources after business hours"
  schedule_expression = "cron(0 1 * * ? *)" # 8 PM EST (1 AM UTC) daily

  tags = {
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
    Name        = "tf-playground-after-hours-check"
  }
}

# CloudWatch Event Target to trigger Lambda function
resource "aws_cloudwatch_event_target" "after_hours_lambda" {
  rule      = aws_cloudwatch_event_rule.after_hours_check.name
  target_id = "AfterHoursCheck"
  arn       = aws_lambda_function.after_hours_check.arn
}

# Lambda function to check for running resources
resource "aws_lambda_function" "after_hours_check" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "tf-playground-after-hours-check"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = 30

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.cost_alerts.arn
      PROJECT_TAG   = "tf-playground"
    }
  }

  tags = {
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
    Name        = "tf-playground-after-hours-check"
  }
}

# Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"

  source {
    content = <<EOF
import boto3
import os
import json
from datetime import datetime

def handler(event, context):
    ec2 = boto3.client('ec2')
    rds = boto3.client('rds')
    elbv2 = boto3.client('elbv2')
    sns = boto3.client('sns')
    
    project_tag = os.environ.get('PROJECT_TAG', 'tf-playground')
    sns_topic_arn = os.environ.get('SNS_TOPIC_ARN')
    
    running_resources = []
    
    # Check for running EC2 instances
    try:
        response = ec2.describe_instances(
            Filters=[
                {'Name': 'instance-state-name', 'Values': ['running']},
                {'Name': 'tag:Project', 'Values': [project_tag]}
            ]
        )
        
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                running_resources.append(f"EC2 Instance: {instance['InstanceId']}")
    except Exception as e:
        print(f"Error checking EC2 instances: {e}")
    
    # Check for running RDS instances
    try:
        response = rds.describe_db_instances()
        for db in response['DBInstances']:
            if db['DBInstanceStatus'] == 'available':
                # Check if it has our project tag
                try:
                    tags_response = rds.list_tags_for_resource(ResourceName=db['DBInstanceArn'])
                    has_project_tag = any(tag['Key'] == 'Project' and tag['Value'] == project_tag 
                                         for tag in tags_response['TagList'])
                    if has_project_tag:
                        running_resources.append(f"RDS Instance: {db['DBInstanceIdentifier']}")
                except:
                    pass
    except Exception as e:
        print(f"Error checking RDS instances: {e}")
    
    # Check for Load Balancers
    try:
        response = elbv2.describe_load_balancers()
        for lb in response['LoadBalancers']:
            if lb['State']['Code'] == 'active':
                # Check if it has our project tag
                try:
                    tags_response = elbv2.describe_tags(ResourceArns=[lb['LoadBalancerArn']])
                    has_project_tag = any(tag['Key'] == 'Project' and tag['Value'] == project_tag 
                                         for tag in tags_response['TagDescriptions'][0]['Tags'])
                    if has_project_tag:
                        running_resources.append(f"Load Balancer: {lb['LoadBalancerName']}")
                except:
                    pass
    except Exception as e:
        print(f"Error checking Load Balancers: {e}")
    
    # If resources are running, send alert
    if running_resources:
        message = f"""
🚨 LAB ENVIRONMENTS RUNNING AFTER HOURS 🚨

The following tf-playground resources are still running after business hours:

{chr(10).join(running_resources)}

This may result in unexpected AWS charges.

To stop these resources:
1. Go to GitHub Actions
2. Run the "Daily Lab Cleanup" workflow
3. Or manually destroy environments

Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}
        """
        
        try:
            sns.publish(
                TopicArn=sns_topic_arn,
                Subject="🚨 Lab Environments Running After Hours",
                Message=message
            )
            print(f"Alert sent for {len(running_resources)} running resources")
        except Exception as e:
            print(f"Error sending SNS notification: {e}")
    else:
        print("No running lab resources found after hours")
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'running_resources': running_resources,
            'count': len(running_resources)
        })
    }
EOF
    filename = "index.py"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "tf-playground-after-hours-lambda-role"

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

  tags = {
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
    Name        = "tf-playground-after-hours-lambda-role"
  }
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "tf-playground-after-hours-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.cost_alerts.arn
      }
    ]
  })
}

# Lambda permission for CloudWatch Events
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.after_hours_check.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.after_hours_check.arn
} 
# Logging Module

This module provides comprehensive logging infrastructure for the Terraform playground project, including CloudWatch log groups, dashboards, alarms, and automated cleanup for demo environments.

## Features

- **CloudWatch Log Groups**: Centralized log aggregation for application and system logs
- **CloudWatch Dashboard**: Real-time monitoring with metrics and log visualization
- **CloudWatch Alarms**: Automated alerting for high error rates and slow response times
- **Demo Cleanup**: Automatic log cleanup to control costs in demo environments
- **Cost Optimized**: 1-day log retention for demo environments

## Usage

```hcl
module "logging" {
  source = "../../modules/logging"

  environment       = "staging"
  aws_region        = "us-east-2"
  alb_name_suffix   = module.loadbalancer.alb_name_suffix
  enable_cleanup    = true  # Demo environment
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name | `string` | n/a | yes |
| aws_region | AWS region | `string` | `"us-east-2"` | no |
| log_retention_days | Number of days to retain logs | `number` | `1` | no |
| alb_name_suffix | ALB name suffix for metrics | `string` | n/a | yes |
| alarm_actions | List of ARNs for alarm actions | `list(string)` | `[]` | no |
| enable_cleanup | Enable automatic log cleanup | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| dashboard_url | CloudWatch dashboard URL |
| application_log_group_name | Application log group name |
| system_log_group_name | System log group name |
| high_error_rate_alarm_arn | High error rate alarm ARN |
| slow_response_time_alarm_arn | Slow response time alarm ARN |

## Resources Created

- CloudWatch Log Groups (application and system logs)
- CloudWatch Dashboard with metrics and log widgets
- CloudWatch Alarms for error rates and response times
- Lambda function for automated log cleanup (optional)
- IAM roles and policies for Lambda cleanup

## Cost Considerations

- **Log Retention**: 1 day for demo environments (vs. 90+ days in production)
- **Cleanup Automation**: Automatic deletion of old log streams
- **Minimal Metrics**: Focus on key application metrics only
- **Demo Tags**: Resources tagged for easy identification and cleanup

## Integration

This module integrates with:
- **ASG Module**: Provides log group names for CloudWatch agent configuration
- **LoadBalancer Module**: Uses ALB metrics for dashboards and alarms
- **Environment Modules**: Provides centralized logging for all environments 
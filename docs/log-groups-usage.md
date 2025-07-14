# Log Groups Usage Guide

## Overview

The log groups are now managed globally and shared across all environments. This provides several benefits:

- **Cost optimization**: Single log group per type per environment
- **Centralized management**: All log groups in one place
- **Consistent naming**: Environment-specific paths (e.g., `/aws/application/tf-playground/staging`)
- **Shared access**: All environments can reference the same log groups

## Accessing Log Group ARNs

### From Terraform Remote State

All environments can access log group ARNs from the global environment's remote state:

```hcl
# Remote state data source
data "terraform_remote_state" "global" {
  backend = "s3"
  config = {
    bucket         = "tf-playground-state-vexus"
    key            = "global/terraform.tfstate"
    region         = "us-east-2"
  }
}

# Access individual log group ARNs
locals {
  application_log_group_arn = data.terraform_remote_state.global.outputs.application_log_group_arns[var.environment]
  system_log_group_arn      = data.terraform_remote_state.global.outputs.system_log_group_arns[var.environment]
  alarm_log_group_arn       = data.terraform_remote_state.global.outputs.alarm_log_group_arns[var.environment]
}
```

### Available Outputs

The global environment provides these outputs:

- `application_log_group_arns` - Map of environment to application log group ARNs
- `system_log_group_arns` - Map of environment to system log group ARNs
- `alarm_log_group_arns` - Map of environment to alarm log group ARNs

### Example Usage in Modules

```hcl
# In a module that needs log group ARNs
module "some_module" {
  source = "../../modules/some_module"
  
  # Pass log group ARNs from global state
  application_log_group_arn = data.terraform_remote_state.global.outputs.application_log_group_arns[var.environment]
  system_log_group_arn      = data.terraform_remote_state.global.outputs.system_log_group_arns[var.environment]
  alarm_log_group_arn       = data.terraform_remote_state.global.outputs.alarm_log_group_arns[var.environment]
}
```

## Log Group Structure

### Environment-Specific Paths

Each environment gets its own log group paths:

- **Application logs**: `/aws/application/tf-playground/{environment}`
- **System logs**: `/aws/system/tf-playground/{environment}`
- **Alarm logs**: `/aws/alarms/tf-playground/{environment}`

### Example ARNs

For the staging environment:
- Application: `arn:aws:logs:us-east-2:123456789012:log-group:/aws/application/tf-playground/staging:*`
- System: `arn:aws:logs:us-east-2:123456789012:log-group:/aws/system/tf-playground/staging:*`
- Alarm: `arn:aws:logs:us-east-2:123456789012:log-group:/aws/alarms/tf-playground/staging:*`

## Use Cases

### 1. IAM Permissions

Grant permissions to write to specific log groups:

```hcl
resource "aws_iam_role_policy" "lambda_logging" {
  name = "lambda-logging-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "${data.terraform_remote_state.global.outputs.application_log_group_arns[var.environment]}:*",
          "${data.terraform_remote_state.global.outputs.system_log_group_arns[var.environment]}:*"
        ]
      }
    ]
  })
}
```

### 2. CloudWatch Dashboards

Reference log groups in dashboard queries:

```hcl
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "tf-playground-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "log"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          query   = "SOURCE '${data.terraform_remote_state.global.outputs.application_log_groups[var.environment]}'\n| fields @timestamp, @message\n| sort @timestamp desc\n| limit 20"
          region  = var.aws_region
          title   = "Recent Application Logs"
        }
      }
    ]
  })
}
```

### 3. Lambda Functions

Configure Lambda functions to write to specific log groups:

```hcl
resource "aws_lambda_function" "example" {
  # ... other configuration ...

  environment {
    variables = {
      LOG_GROUP_NAME = data.terraform_remote_state.global.outputs.application_log_groups[var.environment]
      LOG_GROUP_ARN  = data.terraform_remote_state.global.outputs.application_log_group_arns[var.environment]
    }
  }
}
```

## Benefits of This Approach

1. **Cost Efficiency**: Single log group per type per environment reduces CloudWatch costs
2. **Centralized Management**: All log groups managed in one place
3. **Consistent Access**: All environments use the same pattern to access log groups
4. **Environment Isolation**: Each environment has its own log group paths
5. **Shared State**: No need to duplicate log group definitions across environments

## Migration Notes

- Log groups are now created in the global environment
- Individual environments reference log groups from global state
- No changes needed to application code - log group names remain the same
- Existing logs are preserved during migration 
# Log Groups Module

This module manages global CloudWatch log groups that are shared across all environments in the Terraform playground project.

## 🎯 Purpose

- **Centralized Log Management**: Single log groups shared across environments
- **Cost Optimization**: No duplicate log groups, consistent retention policies
- **Global Access**: All environments can write to the same log groups
- **Lab-Friendly**: Perfect for destroy/recreate cycles

## 🏗️ Architecture

```
Global Environment
├── /aws/application/tf-playground    # Application logs from all environments
├── /aws/ec2/tf-playground           # System logs from all environments
└── /aws/cloudwatch/alarms/tf-playground  # Alarm notifications from all environments
```

## 📋 Features

- **Shared Log Groups**: Single log groups for all environments
- **Configurable Retention**: 1-day default for cost optimization
- **Force Destroy**: Clean destroy/recreate cycles
- **Environment Tagging**: Log streams can be tagged by environment

## 🔧 Usage

### In Global Environment
```hcl
module "log_groups" {
  source = "../../modules/log-groups"
  
  log_retention_days = 1  # Demo environment
}
```

### In Environment Modules
```hcl
# Reference global log groups
data "terraform_remote_state" "global" {
  backend = "s3"
  config = {
    bucket = "tf-playground-state"
    key    = "global/terraform.tfstate"
    region = "us-east-2"
  }
}

# Use global log group names
locals {
  application_log_group = data.terraform_remote_state.global.outputs.application_log_group_name
  system_log_group      = data.terraform_remote_state.global.outputs.system_log_group_name
  alarm_log_group       = data.terraform_remote_state.global.outputs.alarm_log_group_name
}
```

## 📊 Log Stream Strategy

Each environment writes to the same log groups but uses different stream names:

- **Application Logs**: `{environment}-{instance-id}`
- **System Logs**: `{environment}-{instance-id}`
- **Alarm Logs**: `alarm-notifications-{YYYY-MM-DD}`

## 💰 Cost Benefits

- **No Duplicate Storage**: Single log groups across environments
- **Consistent Retention**: 1-day retention for all environments
- **Zero Cost When Empty**: No charges for empty log groups
- **Centralized Management**: Single place to manage retention policies

## 🔍 Monitoring

- **CloudWatch Logs Console**: View all environment logs in one place
- **Log Stream Filtering**: Filter by environment using stream names
- **Cost Tracking**: Single log groups for easier cost monitoring

## 🚀 Deployment

1. **Deploy Global Environment**: Creates shared log groups
2. **Deploy Environment Modules**: Reference global log groups
3. **Configure Applications**: Point to global log group names

This approach provides cost efficiency and centralized management while maintaining environment isolation through log stream naming conventions. 
# Sketch 6: Environment Variables Flow

## Overview

This sketch illustrates how environment-specific variables are configured and how they flow through the Terraform modules to create different configurations for each environment.

## Visual Representation

```
┌─────────────────────────────────────────────────────────────┐
│                  ENVIRONMENT VARIABLES                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   DEV       │    │  STAGING    │    │ PRODUCTION  │     │
│  │variables.tf │    │variables.tf │    │variables.tf │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│         │                   │                   │           │
│         │                   │                   │           │
│  ┌─────▼───────┐    ┌─────▼───────┐    ┌─────▼───────┐     │
│  │ vpc_cidr    │    │ vpc_cidr    │    │ vpc_cidr    │     │
│  │ 192.1.0.0/16│    │ 192.2.0.0/16│    │ 192.3.0.0/16│     │
│  │             │    │             │    │             │     │
│  │ instance_   │    │ instance_   │    │ instance_   │     │
│  │ type        │    │ type        │    │ type        │     │
│  │ t3.micro    │    │ t3.small    │    │ t3.medium   │     │
│  │             │    │             │    │             │     │
│  │ enable_     │    │ enable_     │    │ enable_     │     │
│  │ private     │    │ private     │    │ private     │     │
│  │ true        │    │ true        │    │ true        │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Environment Variable Structure

### Dev Environment Variables

```hcl
# environments/dev/variables.tf
variable "environment" {
  default = "dev"
}

variable "vpc_cidr" {
  default = "192.1.0.0/16"
}

variable "webserver_instance_type" {
  default = "t3.micro"
}

variable "db_instance_type" {
  default = "db.t3.micro"
}

variable "public_subnet_cidrs" {
  default = ["172.12.1.0/24", "172.12.1.32/24"]
}

variable "private_subnet_cidrs" {
  default = ["192.1.0.0/24", "192.1.0.32/24"]
}
```

### Staging Environment Variables

```hcl
# environments/staging/variables.tf
variable "environment" {
  default = "staging"
}

variable "vpc_cidr" {
  default = "192.2.0.0/16"
}

variable "webserver_instance_type" {
  default = "t3.small"
}

variable "db_instance_type" {
  default = "db.t3.small"
}

variable "public_subnet_cidrs" {
  default = ["172.12.2.0/24", "172.12.2.32/24"]
}

variable "private_subnet_cidrs" {
  default = ["192.2.0.0/24", "192.2.0.32/24"]
}
```

### Production Environment Variables

```hcl
# environments/production/variables.tf
variable "environment" {
  default = "production"
}

variable "vpc_cidr" {
  default = "192.3.0.0/16"
}

variable "webserver_instance_type" {
  default = "t3.medium"
}

variable "db_instance_type" {
  default = "db.t3.medium"
}

variable "public_subnet_cidrs" {
  default = ["172.12.3.0/24", "172.12.3.32/24"]
}

variable "private_subnet_cidrs" {
  default = ["192.3.0.0/24", "192.3.0.32/24"]
}
```

## Variable Flow Through Modules

### 1. Root Module Variable Declaration

```hcl
# environments/dev/main.tf
module "networking" {
  source = "../../modules/networking"
  environment = var.environment
  vpc_cidr = var.vpc_cidr
  public_cidrs = var.public_subnet_cidrs
  private_cidrs = var.private_subnet_cidrs
  azs = var.availability_zones
}
```

### 2. Module Variable Definition

```hcl
# modules/networking/variables.tf
variable "environment" {
  description = "Environment name"
  type = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type = string
}

variable "public_cidrs" {
  description = "CIDR blocks for public subnets"
  type = list(string)
}

variable "private_cidrs" {
  description = "CIDR blocks for private subnets"
  type = list(string)
}
```

### 3. Resource Creation with Variables

```hcl
# modules/networking/main.tf
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  # ... other configuration
}

resource "aws_subnet" "public" {
  count = length(var.public_cidrs)
  cidr_block = var.public_cidrs[count.index]
  # ... other configuration
}
```

## Key Principles

### 1. Environment Isolation

- **Unique CIDR Ranges**: Each environment has non-overlapping IP ranges
- **Separate State Files**: Each environment maintains its own state
- **Independent Scaling**: Resources can be sized differently per environment

### 2. Consistent Architecture

- **Same Modules**: All environments use identical module code
- **Same Patterns**: Security groups, routing, and deployment patterns are consistent
- **Same Processes**: Deployment and management processes are uniform

### 3. Environment-Specific Customization

- **Resource Sizing**: Instance types and storage sizes vary by environment
- **Feature Flags**: Environment-specific features can be enabled/disabled
- **Security Settings**: Production may have more restrictive policies

## Benefits

### 1. Predictable Deployments

- **Known Configurations**: Each environment has well-defined settings
- **Consistent Behavior**: Same infrastructure patterns everywhere
- **Easy Troubleshooting**: Issues can be reproduced across environments

### 2. Cost Optimization

- **Right-Sized Resources**: Development uses smaller, cheaper instances
- **Environment-Specific Features**: Production features disabled in dev
- **Resource Management**: Easy to adjust resource allocations per environment

### 3. Team Collaboration

- **Clear Expectations**: Developers know what each environment provides
- **Shared Understanding**: Same variable structure across all environments
- **Easy Onboarding**: New team members can understand the setup quickly

## Advanced Variable Patterns

### Conditional Configuration

```hcl
# Enable features based on environment
variable "enable_monitoring" {
  default = {
    dev = false
    staging = true
    production = true
  }
}

resource "aws_cloudwatch_dashboard" "main" {
  count = var.enable_monitoring[var.environment] ? 1 : 0
  # ... configuration
}
```

### Environment-Specific Tags

```hcl
# Different tagging strategies per environment
locals {
  common_tags = {
    Environment = var.environment
    Project = "tf-playground"
    ManagedBy = "terraform"
  }

  environment_tags = {
    dev = {
      Owner = "development-team"
      CostCenter = "dev-ops"
    }
    staging = {
      Owner = "qa-team"
      CostCenter = "testing"
    }
    production = {
      Owner = "operations-team"
      CostCenter = "production"
    }
  }
}
```

This variable flow approach ensures that the same infrastructure code can be deployed across multiple environments with appropriate customizations while maintaining consistency and predictability.

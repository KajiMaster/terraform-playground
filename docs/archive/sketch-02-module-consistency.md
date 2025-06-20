# Sketch 2: Module Consistency

## Overview

This sketch demonstrates how the same Terraform modules are used across all environments, ensuring consistency and reducing drift.

## Visual Representation

```
┌─────────────────────────────────────────────────────────────┐
│                    SAME TERRAFORM CODE                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   DEV       │    │  STAGING    │    │ PRODUCTION  │     │
│  │             │    │             │    │             │     │
│  │ ┌─────────┐ │    │ ┌─────────┐ │    │ ┌─────────┐ │     │
│  │ │Networking│ │    │ │Networking│ │    │ │Networking│ │     │
│  │ │  Module  │ │    │ │  Module  │ │    │ │  Module  │ │     │
│  │ └─────────┘ │    │ └─────────┘ │    │ └─────────┘ │     │
│  │             │    │             │    │             │     │
│  │ ┌─────────┐ │    │ ┌─────────┐ │    │ ┌─────────┐ │     │
│  │ │Database │ │    │ │Database │ │    │ │Database │ │     │
│  │ │ Module  │ │    │ │ Module  │ │    │ │ Module  │ │     │
│  │ └─────────┘ │    │ └─────────┘ │    │ └─────────┘ │     │
│  │             │    │             │    │             │     │
│  │ ┌─────────┐ │    │ ┌─────────┐ │    │ ┌─────────┐ │     │
│  │ │Compute  │ │    │ │Compute  │ │    │ │Compute  │ │     │
│  │ │ Module  │ │    │ │ Module  │ │    │ │ Module  │ │     │
│  │ └─────────┘ │    │ └─────────┘ │    │ └─────────┘ │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Module Details

### Networking Module

- **Location**: `modules/networking/`
- **Purpose**: VPC, subnets, route tables, NAT Gateway, Internet Gateway
- **Consistency**: Same module used across all environments
- **Variation**: Different CIDR ranges and configurations via variables

### Database Module

- **Location**: `modules/database/`
- **Purpose**: RDS instance, security groups, subnet groups
- **Consistency**: Same module used across all environments
- **Variation**: Different instance types and storage sizes

### Compute Module

- **Location**: `modules/compute/webserver/`
- **Purpose**: EC2 instances, security groups, IAM roles
- **Consistency**: Same module used across all environments
- **Variation**: Different instance types and configurations

### SSM Module

- **Location**: `modules/ssm/`
- **Purpose**: SSM documents, IAM roles, automation
- **Consistency**: Same module used across all environments
- **Variation**: Different environment-specific parameters

## Key Benefits

### 1. Code Reusability

- Single source of truth for each module
- Changes propagate to all environments
- Reduced maintenance overhead

### 2. Consistency Guarantee

- Same infrastructure patterns everywhere
- Predictable behavior across environments
- Reduced configuration drift

### 3. Testing Confidence

- If it works in one environment, it works in all
- Staging truly mirrors production
- Easier troubleshooting

### 4. Scalability

- Easy to add new environments
- Same modules work for any environment
- Consistent deployment patterns

## Implementation Pattern

```hcl
# environments/dev/main.tf
module "networking" {
  source = "../../modules/networking"
  # dev-specific variables
}

# environments/staging/main.tf
module "networking" {
  source = "../../modules/networking"
  # staging-specific variables
}

# environments/production/main.tf
module "networking" {
  source = "../../modules/networking"
  # production-specific variables
}
```

## Environment-Specific Configuration

While the modules are identical, each environment can have different:

- **Variable values** (instance types, CIDR ranges)
- **Feature flags** (enable/disable certain features)
- **Resource sizes** (storage, memory, CPU)
- **Security settings** (restrictive policies in production)

This approach ensures architectural consistency while allowing environment-specific customization.

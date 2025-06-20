# Sketch 5: Module Dependencies

## Overview

This sketch illustrates the dependency relationships between Terraform modules and how they interact to create the complete infrastructure.

## Visual Representation

```
┌─────────────────────────────────────────────────────────────┐
│                    MODULE DEPENDENCIES                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐                                            │
│  │  MAIN.TF    │                                            │
│  │ (Root)      │                                            │
│  └─────┬───────┘                                            │
│        │                                                    │
│        │ Calls                                              │
│        ▼                                                    │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │ Networking  │    │  Database   │    │  Compute    │     │
│  │   Module    │    │   Module    │    │   Module    │     │
│  └─────┬───────┘    └─────┬───────┘    └─────┬───────┘     │
│        │                  │                  │             │
│        │                  │                  │             │
│        │                  │                  │             │
│  ┌─────▼───────┐    ┌─────▼───────┐    ┌─────▼───────┐     │
│  │    VPC      │    │    RDS      │    │     EC2     │     │
│  │ Subnets     │    │  Instance   │    │  Instance   │     │
│  │ Route Tables│    │ Security    │    │ Security    │     │
│  │ NAT Gateway │    │   Groups    │    │   Groups    │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Module Hierarchy

### Root Module (Main.tf)

- **Location**: `environments/dev/main.tf`
- **Purpose**: Orchestrates all modules
- **Responsibilities**:
  - Module instantiation
  - Variable passing
  - Output collection

### Networking Module

- **Location**: `modules/networking/`
- **Dependencies**: None (foundation module)
- **Outputs**: VPC ID, subnet IDs, route table IDs
- **Resources Created**:
  - VPC
  - Public and Private Subnets
  - Internet Gateway
  - NAT Gateway
  - Route Tables
  - Route Table Associations

### Database Module

- **Location**: `modules/database/`
- **Dependencies**: Networking Module
- **Inputs**: VPC ID, private subnet IDs, security group ID
- **Outputs**: Database endpoint, port, name
- **Resources Created**:
  - RDS Instance
  - Database Security Group
  - Database Subnet Group

### Compute Module

- **Location**: `modules/compute/webserver/`
- **Dependencies**: Networking Module, Database Module
- **Inputs**: VPC ID, public subnet IDs, database endpoint
- **Outputs**: Instance ID, public IP, security group ID
- **Resources Created**:
  - EC2 Instance
  - Web Server Security Group
  - IAM Role and Policies
  - Elastic IP

### SSM Module

- **Location**: `modules/ssm/`
- **Dependencies**: Compute Module, Database Module
- **Inputs**: Instance ID, database credentials
- **Outputs**: SSM document name, automation status
- **Resources Created**:
  - SSM Automation Document
  - IAM Role for SSM
  - SSM Execution Resources

## Dependency Flow

### 1. Foundation Layer

```
Networking Module
├── VPC
├── Subnets
├── Route Tables
└── Gateways
```

### 2. Data Layer

```
Database Module (depends on Networking)
├── RDS Instance
├── Security Groups
└── Subnet Groups
```

### 3. Application Layer

```
Compute Module (depends on Networking + Database)
├── EC2 Instance
├── Security Groups
└── IAM Roles
```

### 4. Operations Layer

```
SSM Module (depends on Compute + Database)
├── SSM Documents
├── IAM Roles
└── Automation Resources
```

## Module Communication

### Variable Passing

```hcl
# Root module passes variables to child modules
module "database" {
  source = "../../modules/database"
  vpc_id = module.networking.vpc_id
  private_subnets = module.networking.private_subnet_ids
  webserver_security_group_id = module.webserver.security_group_id
}
```

### Output Consumption

```hcl
# Child modules provide outputs to parent
output "database_endpoint" {
  value = module.database.db_instance_address
}

output "webserver_public_ip" {
  value = module.webserver.public_ip
}
```

## Benefits of This Structure

### 1. Modularity

- **Reusable Components**: Modules can be used across environments
- **Clear Boundaries**: Each module has a specific responsibility
- **Easy Testing**: Modules can be tested independently

### 2. Dependency Management

- **Explicit Dependencies**: Clear relationships between modules
- **Automatic Ordering**: Terraform handles dependency resolution
- **Parallel Execution**: Independent modules can run in parallel

### 3. Maintainability

- **Single Responsibility**: Each module has one clear purpose
- **Easy Updates**: Changes to one module don't affect others
- **Version Control**: Modules can be versioned independently

### 4. Scalability

- **Easy Extension**: New modules can be added easily
- **Environment Flexibility**: Modules can be used in different combinations
- **Team Collaboration**: Different teams can work on different modules

## Implementation Example

### Root Module Structure

```hcl
# environments/dev/main.tf
module "networking" {
  source = "../../modules/networking"
  # networking variables
}

module "database" {
  source = "../../modules/database"
  vpc_id = module.networking.vpc_id
  # database variables
}

module "webserver" {
  source = "../../modules/compute/webserver"
  vpc_id = module.networking.vpc_id
  db_host = module.database.db_instance_address
  # webserver variables
}

module "ssm" {
  source = "../../modules/ssm"
  webserver_instance_id = module.webserver.instance_id
  # ssm variables
}
```

This modular approach ensures clean separation of concerns, reusability, and maintainability across the entire infrastructure codebase.

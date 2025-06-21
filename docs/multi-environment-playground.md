# Multi-Environment Terraform Playground

## Overview

This document describes the complete multi-environment Terraform playground setup, including infrastructure, state management, and deployment strategies.

## Architecture Overview

### Environment Structure

```
terraform-playground/
├── environments/
│   ├── dev/          # Development environment
│   ├── staging/      # Staging environment (to be implemented)
│   └── production/   # Production environment (to be implemented)
├── modules/
│   ├── networking/   # VPC, subnets, routing
│   ├── compute/      # EC2 instances, security groups
│   ├── database/     # RDS instances, subnet groups
│   ├── ssm/          # SSM automation, documents
│   ├── secrets/      # Secrets management
│   └── oidc/         # GitHub Actions OIDC setup
├── docs/             # Documentation
└── .github/workflows/ # CI/CD workflows (to be implemented)
```

### Infrastructure Components

- **VPC**: Isolated network per environment
- **Subnets**: Public and private subnets with NAT Gateway
- **EC2**: Web servers with IAM roles
- **RDS**: Database instances in private subnets
- **SSM**: Automation for database bootstrapping
- **S3**: Remote state storage
- **DynamoDB**: State locking
- **Secrets Manager**: Database credentials management

## State Management

### Remote State Configuration

- **S3 Bucket**: `tf-playground-state`
- **DynamoDB Table**: `tf-playground-locks`
- **Region**: `us-east-2`
- **State Files**:
  - `dev/terraform.tfstate`
  - `staging/terraform.tfstate` (future)
  - `production/terraform.tfstate` (future)

### Backend Configuration

```hcl
terraform {
  backend "s3" {
    bucket         = "tf-playground-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "tf-playground-locks"
    encrypt        = true
  }
}
```

## Deployment Strategy

### Current Implementation (DEV)

1. **Manual Deployment**: Developer-controlled deployment
2. **Two-Step Process**:
   - `terraform apply` - Deploy infrastructure
   - `aws ssm start-automation-execution` - Bootstrap database
3. **Verification**: Check web application endpoints

### Future CI/CD Pipeline (To Be Implemented)

- **GitHub Actions Workflow**: Automated deployment for staging/production
- **Authentication**: OIDC (OpenID Connect) - no stored credentials
- **Environments**: Staging (auto), Production (manual approval)
- **Actions**: Plan, Apply, Database Bootstrap

### OIDC Setup (To Be Implemented)

- **Provider**: GitHub Actions OIDC provider
- **Role**: `github-actions-{environment}`
- **Permissions**: S3, DynamoDB, EC2, RDS, SSM, IAM (limited)

## Environment Configuration

### Dev Environment

- **Instance Type**: `t3.micro`
- **Database**: `db.t3.micro`
- **Purpose**: Development and testing
- **Deployment**: Manual (developer control)
- **Status**: ✅ **Fully Implemented**

### Staging Environment

- **Instance Type**: `t3.small`
- **Database**: `db.t3.small`
- **Purpose**: Integration testing
- **Deployment**: Automated (GitHub Actions) - To be implemented
- **Status**: 🚧 **To Be Implemented**

### Production Environment

- **Instance Type**: `t3.medium`
- **Database**: `db.t3.medium`
- **Purpose**: Live production
- **Deployment**: Manual approval required - To be implemented
- **Status**: 🚧 **To Be Implemented**

## Module Consistency

### Same Code, Different Configurations

All environments use identical modules with environment-specific variables:

```hcl
# environments/dev/variables.tf
variable "webserver_instance_type" {
  default = "t3.micro"
}

# environments/production/variables.tf (future)
variable "webserver_instance_type" {
  default = "t3.medium"
}
```

### Benefits

- **Predictable Deployments**: Same infrastructure patterns
- **Easy Testing**: Staging will mirror production
- **Reduced Drift**: Consistent configurations
- **Scalability**: Easy to add new environments

## Security Features

### Network Security

- **Private Subnets**: Database instances isolated
- **Security Groups**: Restrictive access policies
- **NAT Gateway**: Private subnet internet access
- **VPC Isolation**: Each environment in separate VPC

### Access Control

- **OIDC Authentication**: Planned for CI/CD (no stored AWS credentials)
- **IAM Roles**: Least privilege access
- **State Encryption**: S3 server-side encryption
- **State Locking**: DynamoDB prevents concurrent modifications

### Secrets Management

- **Database Credentials**: Stored in AWS Secrets Manager
- **SSH Keys**: Managed via AWS Systems Manager
- **Environment Variables**: No secrets in code

## Database Bootstrap

### Automated Process

The database bootstrap is fully automated using AWS SSM:

1. **SSM Automation Document**: `dev-database-automation`
2. **Dynamic Values**: All parameters retrieved from Terraform outputs and Secrets Manager
3. **No Hardcoded Values**: Fully reusable across environments
4. **Enterprise-Ready**: Compatible with CI/CD pipelines

### Bootstrap Steps

1. Install MariaDB client utilities
2. Create database schema (contacts table)
3. Insert sample data (5 contacts)
4. Verify setup completion

## Cost Optimization

### Resource Sizing

- **Dev**: Minimal resources for cost efficiency
- **Staging**: Medium resources for realistic testing (future)
- **Production**: Appropriate resources for performance (future)

### Cost Monitoring

- **AWS Cost Explorer**: Track environment costs
- **Resource Tagging**: Environment-specific cost allocation
- **Auto-scaling**: Scale based on demand (future)

## Monitoring and Observability

### Infrastructure Monitoring

- **CloudWatch**: Metrics and logging
- **Health Checks**: Web application health endpoints
- **Database Monitoring**: RDS performance insights

### Application Monitoring

- **Health Endpoint**: `http://<webserver-ip>:8080/health`
- **Data Endpoint**: `http://<webserver-ip>:8080/` (returns JSON with contacts)
- **Logs**: Application logs via CloudWatch

## Future Enhancements

### Planned Features

1. **CI/CD Pipeline**: GitHub Actions workflow for automated deployments
2. **Staging Environment**: Full staging environment implementation
3. **Production Environment**: Production environment with proper security
4. **Monitoring**: Enhanced monitoring and alerting
5. **Auto-scaling**: Application auto-scaling groups
6. **Load Balancing**: Application Load Balancer implementation

### Learning Objectives

This playground serves as a learning platform for:

- **Infrastructure as Code**: Terraform best practices
- **Multi-Environment Management**: Environment isolation and consistency
- **Security**: IAM, VPC, and secrets management
- **Automation**: SSM automation and CI/CD integration
- **Monitoring**: Infrastructure and application monitoring

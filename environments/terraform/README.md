# Universal Terraform Root Module

This directory contains a universal Terraform configuration that can be used across multiple environments using separate state files and workspace management.

## Structure

```
environments/terraform/
├── main.tf              # Universal main configuration
├── variables.tf         # Universal variable definitions
├── outputs.tf           # Universal outputs
├── backend.tf           # Backend configuration (currently staging)
├── backend-production.tf # Production backend configuration
├── staging.tfvars       # Staging-specific variable values
├── production.tfvars    # Production-specific variable values
└── setup-staging.sh     # Setup script for staging workspace
```

## How to Use

### For Staging Environment

1. **Current Setup**: The `backend.tf` is already configured for staging state file (`terraform-staging.tfstate`)

2. **Initialize and Deploy**:
   ```bash
   cd environments/terraform
   terraform init -reconfigure
   terraform plan -var-file=staging.tfvars
   terraform apply -var-file=staging.tfvars
   ```

### For Production Environment

1. **Switch Backend Configuration**:
   ```bash
   ./switch-environment.sh production
   ```

2. **Deploy**:
   ```bash
   terraform plan -var-file=production.tfvars
   terraform apply -var-file=production.tfvars
   ```

## Benefits of This Approach

1. **Single Codebase**: All environments use the same Terraform configuration files
2. **Environment Isolation**: Each environment has its own state file
3. **Easy Promotion**: Simply switch backend and workspace to promote from staging to production
4. **DRY Principle**: No code duplication between environments
5. **Consistent Infrastructure**: All environments are guaranteed to use the same infrastructure code

## State File Management

- **Staging**: `s3://tf-playground-state-vexus/workspaces/terraform-staging.tfstate`
- **Production**: `s3://tf-playground-state-vexus/workspaces/terraform-production.tfstate`

## Environment-Specific Values

Environment-specific values are managed through `.tfvars` files:
- `staging.tfvars` - Staging-specific variable values
- `production.tfvars` - Production-specific variable values

## Workspace Commands

```bash
# List all workspaces
terraform workspace list

# Show current workspace
terraform workspace show

# Create new workspace
terraform workspace new <workspace-name>

# Switch to workspace
terraform workspace select <workspace-name>

# Delete workspace (if empty)
terraform workspace delete <workspace-name>
```

## Architecture Variations

This Terraform configuration supports multiple compute platform architectures based on the `.tfvars` file used. Each configuration creates different infrastructure layouts optimized for specific use cases.

### Available Configurations

| Configuration | Compute Platform | Network Model | Use Case |
|---------------|-----------------|---------------|----------|
| `working_ecs_dev.tfvars` | **ECS Fargate** | Public subnets only | Development & Testing |
| `working_eks_dev.tfvars` | **EKS (Kubernetes)** | Public subnets only | K8s Development |
| `working_ecs_staging.tfvars` | **ECS Fargate** | Private subnets + NAT | Cost-optimized Staging |
| `working_eks_staging.tfvars` | **EKS (Kubernetes)** | Private subnets + NAT | K8s Staging |
| `staging.tfvars` | **ECS + EKS** | Private subnets + NAT | Full Pre-production |
| `production.tfvars` | **ECS Fargate** | Private subnets + NAT + WAF | Production |

### ECS Architecture (`working_ecs_dev.tfvars`)

```
┌─────────────────────────────────────────────────────────────┐
│                        Internet Gateway                     │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────┴───────────────────────────────────┐
│                    Application Load Balancer                │
│                    (Blue/Green Target Groups)               │
└─────────────────────────┬───────────────────────────────────┘
                          │
    ┌─────────────────────┴─────────────────────┐
    │                     │                     │
┌───▼──────┐         ┌────▼──────┐         ┌────▼──────┐
│ Public   │         │ Public    │         │           │
│ Subnet   │         │ Subnet    │         │    RDS    │
│ (ECS)    │         │ (ECS)     │         │ Database  │
│          │         │           │         │           │
│ Fargate  │         │ Fargate   │         │           │
│ Tasks    │         │ Tasks     │         │           │
└──────────┘         └───────────┘         └───────────┘
```

**Key Features:**
- **Container Platform**: ECS Fargate (serverless containers)
- **Blue/Green Deployment**: Zero-downtime deployments
- **Cost Optimized**: No NAT Gateway, public subnets only
- **ECS Exec**: Enabled for container debugging
- **Auto Scaling**: Built-in ECS service scaling

### EKS Architecture (`working_eks_dev.tfvars`)

```
┌─────────────────────────────────────────────────────────────┐
│                        Internet Gateway                     │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────┴───────────────────────────────────┐
│                    Application Load Balancer                │
│                   (Kubernetes Ingress)                      │
└─────────────────────────┬───────────────────────────────────┘
                          │
    ┌─────────────────────┴─────────────────────┐
    │                     │                     │
┌───▼──────┐         ┌────▼──────┐         ┌────▼──────┐
│ Public   │         │ Public    │         │           │
│ Subnet   │         │ Subnet    │         │    RDS    │
│          │         │           │         │ Database  │
│ EKS Node │         │ EKS Node  │         │           │
│ Group    │         │ Group     │         │           │
│          │         │           │         │           │
│ ┌─────┐  │         │ ┌─────┐   │         │           │
│ │ Pod │  │         │ │ Pod │   │         │           │
│ └─────┘  │         │ └─────┘   │         │           │
└──────────┘         └───────────┘         └───────────┘
```

**Key Features:**
- **Container Platform**: Kubernetes (EKS) with managed node groups
- **Kubernetes Services**: Full K8s ecosystem (pods, services, ingress)
- **Node Groups**: t3.small instances for pod distribution
- **Cost Optimized**: Public subnets, no Fargate
- **Kubectl Access**: Direct cluster management

### Production Architecture (`production.tfvars`)

```
┌─────────────────────────────────────────────────────────────┐
│                           WAF                               │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────┴───────────────────────────────────┐
│                        Internet Gateway                     │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────┴───────────────────────────────────┐
│                    Application Load Balancer                │
└─────────────────────────┬───────────────────────────────────┘
                          │
    ┌─────────────────────┴─────────────────────┐
    │                     │                     │
┌───▼──────┐         ┌────▼──────┐         ┌────▼──────┐
│ Public   │         │ Public    │         │ Private   │
│ Subnet   │         │ Subnet    │         │ Subnet    │
│ (ALB)    │         │ (ALB)     │         │           │
└──────────┘         └───────────┘         │    RDS    │
    │                     │                │ Database  │
    └─────────┬───────────┘                │           │
              │                            └───────────┘
┌─────────────▼─────────────┐
│        NAT Gateway        │
└─────────────┬─────────────┘
              │
    ┌─────────┴─────────────┐
    │                       │
┌───▼──────┐         ┌──────▼───┐
│ Private  │         │ Private  │
│ Subnet   │         │ Subnet   │
│          │         │          │
│ ECS      │         │ ECS      │
│ Fargate  │         │ Fargate  │
│ Tasks    │         │ Tasks    │
└──────────┘         └──────────┘
```

**Key Features:**
- **Security**: WAF protection, private subnets for workloads
- **High Availability**: Multi-AZ deployment
- **Controlled Internet Access**: NAT Gateway for outbound traffic
- **Production Hardening**: Enhanced monitoring and logging

## Configuration Switching

### Quick Environment Switch

```bash
# Development environments (public subnets, cost-optimized)
terraform plan -var-file=working_ecs_dev.tfvars    # ECS development
terraform apply -var-file=working_ecs_dev.tfvars

terraform plan -var-file=working_eks_dev.tfvars    # EKS development
terraform apply -var-file=working_eks_dev.tfvars

# Staging environments (private subnets + NAT, staging security)
./switch-env.sh staging
terraform plan -var-file=working_ecs_staging.tfvars  # ECS staging
terraform apply -var-file=working_ecs_staging.tfvars

terraform plan -var-file=working_eks_staging.tfvars  # EKS staging  
terraform apply -var-file=working_eks_staging.tfvars

# Full staging (both ECS + EKS)
terraform plan -var-file=staging.tfvars
terraform apply -var-file=staging.tfvars

# Production (includes backend switching)
./switch-env.sh production
terraform plan -var-file=production.tfvars
terraform apply -var-file=production.tfvars

# Switch backend state files for different environments
./switch-env.sh dev      # Switches to dev backend state
./switch-env.sh staging  # Switches to staging backend state
```

### Key Differences Summary

| Feature | ECS Dev | EKS Dev | ECS Staging | EKS Staging | Full Staging | Production |
|---------|---------|---------|-------------|-------------|--------------|------------|
| **Networking** | Public only | Public only | Private + NAT | Private + NAT | Private + NAT | Private + NAT + WAF |
| **Compute** | ECS Fargate | EKS Nodes (t3.small) | ECS Fargate | EKS Nodes (t3.small) | Both ECS+EKS | ECS Fargate |
| **Instance Size** | Micro | Small (K8s req) | Micro | Small (K8s req) | Mixed | Micro |
| **Blue/Green** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Auto Scaling** | ECS Service | K8s HPA | ECS Service | K8s HPA | Both | ECS Service |
| **Monitoring** | Basic | Basic | Enhanced | Enhanced | Enhanced | Full |
| **Security** | Development | Development | Staging | Staging | Pre-prod | Production |
| **ALB Controller** | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ |

## Migration from Existing Environments

To migrate from the existing `environments/staging` and `environments/production` directories:

1. **Backup existing state**:
   ```bash
   terraform state pull > staging-backup.tfstate
   ```

2. **Import existing resources** (if needed):
   ```bash
   terraform import <resource_address> <resource_id>
   ```

3. **Verify with plan**:
   ```bash
   terraform plan -var-file=staging.tfvars
   ``` 
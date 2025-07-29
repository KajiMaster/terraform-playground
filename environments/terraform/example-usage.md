# Example: Pure Terraform Workspace Usage

## Setup (One-time)
```bash
# Initialize Terraform
terraform init

# Create workspaces for each environment
terraform workspace new staging
terraform workspace new production
```

## Daily Usage

### Deploy to Staging
```bash
# Switch to staging workspace
terraform workspace select staging

# Plan and apply with staging variables
terraform plan -var-file=staging.tfvars
terraform apply -var-file=staging.tfvars
```

### Deploy to Production
```bash
# Switch to production workspace
terraform workspace select production

# Plan and apply with production variables
terraform plan -var-file=production.tfvars
terraform apply -var-file=production.tfvars
```

### Check Current Environment
```bash
# See which workspace you're on
terraform workspace show

# List all available workspaces
terraform workspace list
```

## That's It!

No custom scripts needed. Just pure Terraform workspace commands:

- `terraform workspace select <environment>` - Switch environments
- `terraform workspace show` - See current environment
- `terraform workspace list` - List all environments

Each workspace automatically gets its own state file:
- Staging: `s3://tf-playground-state-vexus/workspaces/terraform.tfstate/env:/staging`
- Production: `s3://tf-playground-state-vexus/workspaces/terraform.tfstate/env:/production`

## Simple Workflow

```bash
# 1. Switch to staging
terraform workspace select staging
terraform plan -var-file=staging.tfvars
terraform apply -var-file=staging.tfvars

# 2. Switch to production
terraform workspace select production
terraform plan -var-file=production.tfvars
terraform apply -var-file=production.tfvars
```

This approach keeps it simple:
- ✅ Pure Terraform commands
- ✅ Separate state files per environment
- ✅ Clear var file usage
- ✅ No custom scripts or complex configurations 
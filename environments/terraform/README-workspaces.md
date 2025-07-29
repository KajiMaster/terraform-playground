# Terraform Workspace Management

This directory uses **pure Terraform workspaces** to manage multiple environments with a single backend configuration.

## How It Works

### Single Backend Configuration
```hcl
# backend.tf - Universal for all environments
terraform {
  backend "s3" {
    bucket         = "tf-playground-state-vexus"
    key            = "workspaces/terraform.tfstate"  # Single key
    region         = "us-east-2"
    dynamodb_table = "tf-playground-locks"
    encrypt        = false
  }
}
```

### Workspace-Based State Files
Terraform automatically creates separate state files for each workspace:
- **Staging**: `s3://tf-playground-state-vexus/workspaces/terraform.tfstate/env:/staging`
- **Production**: `s3://tf-playground-state-vexus/workspaces/terraform.tfstate/env:/production`
- **Default**: `s3://tf-playground-state-vexus/workspaces/terraform.tfstate/env:/default`

## Usage

### Switch Between Environments
```bash
# Switch to staging
terraform workspace select staging

# Switch to production  
terraform workspace select production

# Create new workspace (if it doesn't exist)
terraform workspace new staging
terraform workspace new production
```

### Workspace Commands
```bash
# List all workspaces
terraform workspace list

# Show current workspace
terraform workspace show

# Create new workspace
terraform workspace new <environment>

# Select workspace
terraform workspace select <environment>

# Delete workspace (be careful!)
terraform workspace delete <environment>
```

### Apply Changes
```bash
# For staging
terraform workspace select staging
terraform plan -var-file=staging.tfvars
terraform apply -var-file=staging.tfvars

# For production
terraform workspace select production
terraform plan -var-file=production.tfvars
terraform apply -var-file=production.tfvars
```

## Benefits

✅ **Universal backend.tf** - No need to manage different backend configurations  
✅ **Clear state separation** - Each environment has its own state file  
✅ **Native Terraform commands** - No custom scripts needed  
✅ **CI/CD friendly** - Workspaces are created automatically in pipelines  
✅ **No variable interpolation issues** - Backend configuration is static  

## State File Structure

```
s3://tf-playground-state-vexus/
├── workspaces/
│   └── terraform.tfstate/
│       ├── env:/default
│       ├── env:/staging
│       └── env:/production
```

## GitHub Workflows

- **Staging**: `.github/workflows/staging-workspace-terraform.yml`
- **Production**: `.github/workflows/production-workspace-terraform.yml`

Both workflows automatically:
1. Initialize Terraform
2. Create/select the appropriate workspace
3. Apply environment-specific variables
4. Deploy to the correct environment

## Why This Approach?

This solves the common issue with trying to use variables in backend configuration:
```hcl
# ❌ This doesn't work - variables not allowed in backend
key = "workspaces/${var.environment}/terraform.tfstate"

# ✅ This works - static key with workspace separation
key = "workspaces/terraform.tfstate"
```

The workspace feature automatically handles the environment separation without needing dynamic backend configuration.

## Quick Reference

```bash
# Initialize and set up workspaces
terraform init
terraform workspace new staging
terraform workspace new production

# Deploy to staging
terraform workspace select staging
terraform plan -var-file=staging.tfvars
terraform apply -var-file=staging.tfvars

# Deploy to production
terraform workspace select production
terraform plan -var-file=production.tfvars
terraform apply -var-file=production.tfvars
``` 
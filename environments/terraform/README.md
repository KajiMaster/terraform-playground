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
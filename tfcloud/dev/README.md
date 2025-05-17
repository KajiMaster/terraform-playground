# Terraform Cloud Workspace Management

This directory contains the Terraform configuration for managing the Terraform Cloud workspace variables and settings for the `terraform-playground-dev` workspace.

## Prerequisites

1. Terraform Cloud account and organization
2. Terraform Cloud API token
3. AWS credentials (access key and secret key)

## Setup

1. Copy the example variables file and update it with your values:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Set your Terraform Cloud API token as an environment variable:

   ```bash
   export TFE_TOKEN=your-tfe-token-here
   ```

3. Initialize Terraform:

   ```bash
   terraform init
   ```

4. Review the planned changes:

   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

## What This Manages

This configuration manages the following in your Terraform Cloud workspace:

### Environment Variables

- `AWS_ACCESS_KEY_ID` (sensitive)
- `AWS_SECRET_ACCESS_KEY` (sensitive)

### Terraform Variables

- `environment`
- `aws_region`
- `vpc_cidr`
- `public_subnet_cidrs`
- `private_subnet_cidrs`
- `availability_zones`
- `webserver_instance_type`
- `key_name`
- `db_instance_type`
- `db_name`

## Security Notes

1. The `terraform.tfvars` file contains sensitive information and should never be committed to version control
2. The AWS credentials are stored as sensitive variables in Terraform Cloud
3. The Terraform Cloud API token should be kept secure and never committed to version control

## Updating Variables

To update workspace variables:

1. Modify the values in your `terraform.tfvars` file
2. Run `terraform plan` to see the changes
3. Run `terraform apply` to apply the changes

## Adding New Variables

To add new variables to the workspace:

1. Add the variable definition to `variables.tf`
2. Add the variable resource to `main.tf`
3. Add the variable value to `terraform.tfvars`
4. Apply the changes using `terraform apply`

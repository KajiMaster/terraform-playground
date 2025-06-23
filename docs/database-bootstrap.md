# Database Bootstrap Guide

This guide covers the automated database bootstrapping process using AWS Systems Manager (SSM) automation.

## Prerequisites

- SSH key pair `tf-playground-key` created in AWS
- Private key saved as `~/.ssh/tf-playground-key.pem` with permissions `400`
- `terraform.tfvars` file in your environment directory with `key_name = "tf-playground-key"`

## Overview

This document describes how to populate the database with sample data using AWS SSM Automation. This is a streamlined, enterprise-ready approach that automatically retrieves all required values from Terraform outputs and AWS Secrets Manager.

## Quick Start (Two-Step Process)

### Step 1: Deploy Infrastructure

```bash
cd environments/dev
terraform apply
```

### Step 2: Bootstrap Database

```bash
# Get all the values first to avoid shell parsing issues
DB_ENDPOINT=$(terraform output -raw database_endpoint | sed 's/:3306$//')
DB_NAME=$(terraform output -raw database_name)
SUFFIX=$(terraform output -raw random_suffix)
SECRET_PATH="/tf-playground/dev/database/credentials-${SUFFIX}"
DB_USERNAME=$(aws secretsmanager get-secret-value --secret-id "$SECRET_PATH" --region us-east-2 --query SecretString --output text | jq -r '.username')
DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id "$SECRET_PATH" --region us-east-2 --query SecretString --output text | jq -r '.password')
INSTANCE_ID=$(terraform output -raw webserver_instance_id)
ROLE_ARN=$(aws iam get-role --role-name dev-ssm-automation-role --query 'Role.Arn' --output text)

# Run the automation
aws ssm start-automation-execution \
  --document-name "dev-database-automation" \
  --parameters "DatabaseEndpoint=$DB_ENDPOINT,DatabaseName=$DB_NAME,DatabaseUsername=$DB_USERNAME,DatabasePassword=$DB_PASSWORD,InstanceId=$INSTANCE_ID,AutomationAssumeRole=$ROLE_ARN" \
  --region us-east-2
```

### Step 3: Monitor Execution (Optional)

```bash
# Get the execution ID from the previous command output
aws ssm describe-automation-executions --filters Key=ExecutionId,Values=<execution-id>
```

## What This Does

### 1. Install Dependencies

- Updates system packages
- Installs MariaDB client utilities

### 2. Create Database Schema

- Creates `contacts` table with:
  - `id` (auto-increment primary key)
  - `name` (VARCHAR 100)
  - `email` (VARCHAR 100, unique)
  - `phone` (VARCHAR 20)
  - `created_at` (TIMESTAMP)

### 3. Insert Sample Data

- Adds 5 sample contacts:
  - John Doe (john.doe@example.com)
  - Jane Smith (jane.smith@example.com)
  - Bob Johnson (bob.johnson@example.com)
  - Alice Brown (alice.brown@example.com)
  - Charlie Wilson (charlie.wilson@example.com)

### 4. Verify Setup

- Counts records in the contacts table
- Reports completion status

## Environment-Specific Commands

### Development Environment

```bash
cd environments/dev

# Bootstrap database with sample data (one-liner)
aws ssm start-automation-execution --document-name "dev-database-automation" --parameters "DatabaseEndpoint=$(terraform output -raw database_endpoint | sed 's/:3306$//'),DatabaseName=$(terraform output -raw database_name),DatabaseUsername=$(aws secretsmanager get-secret-value --secret-id /tf-playground/dev/database/credentials-$(terraform output -raw random_suffix) --region us-east-2 --query SecretString --output text | jq -r '.username'),DatabasePassword=\"$(aws secretsmanager get-secret-value --secret-id /tf-playground/dev/database/credentials-$(terraform output -raw random_suffix) --region us-east-2 --query SecretString --output text | jq -r '.password')\",InstanceId=$(terraform output -raw webserver_instance_id),AutomationAssumeRole=$(aws iam get-role --role-name dev-ssm-automation-role --query 'Role.Arn' --output text)" --region us-east-2
```

### Staging Environment

```bash
cd environments/staging

# Bootstrap database with sample data
aws ssm start-automation-execution --document-name "staging-database-automation" --parameters "DatabaseEndpoint=$(terraform output -raw database_endpoint | sed 's/:3306$//'),DatabaseName=$(terraform output -raw database_name),DatabaseUsername=$(aws secretsmanager get-secret-value --secret-id /tf-playground/staging/database/credentials-$(terraform output -raw random_suffix) --region us-east-2 --query SecretString --output text | jq -r '.username'),DatabasePassword=\"$(aws secretsmanager get-secret-value --secret-id /tf-playground/staging/database/credentials-$(terraform output -raw random_suffix) --region us-east-2 --query SecretString --output text | jq -r '.password')\",InstanceId=$(terraform output -raw webserver_instance_id),AutomationAssumeRole=$(aws iam get-role --role-name staging-ssm-automation-role --query 'Role.Arn' --output text)" --region us-east-2
```

### Production Environment

```bash
cd environments/production
terraform apply

# Get all the values first
DB_ENDPOINT=$(terraform output -raw database_endpoint | sed 's/:3306$//')
DB_NAME=$(terraform output -raw database_name)
SUFFIX=$(terraform output -raw random_suffix)
SECRET_PATH="/tf-playground/production/database/credentials-${SUFFIX}"
DB_USERNAME=$(aws secretsmanager get-secret-value --secret-id "$SECRET_PATH" --region us-east-2 --query SecretString --output text | jq -r '.username')
DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id "$SECRET_PATH" --region us-east-2 --query SecretString --output text | jq -r '.password')
INSTANCE_ID=$(terraform output -raw webserver_instance_id)
ROLE_ARN=$(aws iam get-role --role-name production-ssm-automation-role --query 'Role.Arn' --output text)

# Run the automation
aws ssm start-automation-execution \
  --document-name "production-database-automation" \
  --parameters "DatabaseEndpoint=$DB_ENDPOINT,DatabaseName=$DB_NAME,DatabaseUsername=$DB_USERNAME,DatabasePassword=$DB_PASSWORD,InstanceId=$INSTANCE_ID,AutomationAssumeRole=$ROLE_ARN" \
  --region us-east-2
```

## Recent Improvements (Version 2)

### Random Suffixes for Secrets
- Secrets now include random 4-character suffixes to prevent deletion recovery window conflicts
- Example: `/tf-playground/dev/database/credentials-abc1`
- This allows for clean destroy/rebuild cycles in lab environments

### Enhanced Password Handling
- SSM automation now uses environment variables to handle special characters in passwords
- Prevents shell syntax errors from characters like `!`, `*`, `(`, `)`, `:`, etc.
- More robust and secure approach

### Simplified Prerequisites
- No longer requires manual KMS key or Secrets Manager setup
- All secrets are created automatically by Terraform
- SSH key is the only prerequisite

## Troubleshooting

### Common Issues

1. **jq not installed**: Install jq for JSON parsing: `sudo yum install -y jq` (Amazon Linux) or `sudo apt-get install jq` (Ubuntu)
2. **Permission errors**: Ensure your AWS credentials have appropriate SSM and Secrets Manager permissions
3. **Database connection**: Verify security groups allow EC2 to RDS communication
4. **Parameter parsing errors**: Use the variable-based approach above to avoid shell parsing issues with special characters

### Manual Database Setup (Alternative)

If SSM automation fails, you can SSH into the EC2 instance and run the commands manually:

```bash
# SSH into instance
ssh -i ~/.ssh/tf-playground-key.pem ec2-user@<public-ip>

# Install MariaDB client
sudo yum install -y mariadb1011-client-utils

# Get database credentials from Secrets Manager
SUFFIX=$(terraform output -raw random_suffix)
SECRET_PATH="/tf-playground/dev/database/credentials-${SUFFIX}"
DB_CREDS=$(aws secretsmanager get-secret-value --secret-id "$SECRET_PATH" --region us-east-2 --query SecretString --output text)
DB_HOST=$(echo $DB_CREDS | jq -r '.host')
DB_USER=$(echo $DB_CREDS | jq -r '.username')
DB_PASS=$(echo $DB_CREDS | jq -r '.password')
DB_NAME=$(echo $DB_CREDS | jq -r '.dbname')

# Run the database setup manually
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME < /path/to/init.sql
```

## Security Notes

- Database credentials are stored in AWS Secrets Manager with random suffixes
- KMS keys are used for encryption with environment-specific naming
- SSM automation uses least-privilege IAM policies
- All values are dynamically retrieved from Terraform outputs and Secrets Manager
- No hardcoded values in the automation process
- Special characters in passwords are properly handled via environment variables

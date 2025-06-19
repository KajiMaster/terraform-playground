# Database Bootstrap Documentation

## Overview

This document describes how to populate the database with sample data using AWS SSM Automation. This is a streamlined, enterprise-ready approach that automatically retrieves all required values from Terraform outputs and AWS Secrets Manager.

## Quick Start (Two-Step Process)

### Step 1: Deploy Infrastructure

```bash
cd environments/dev
terraform apply -auto-approve
```

### Step 2: Bootstrap Database

```bash
aws ssm start-automation-execution \
  --document-name "dev-database-automation" \
  --parameters "DatabaseEndpoint=$(terraform output -raw database_endpoint | sed 's/:3306$//'),DatabaseName=$(terraform output -raw database_name),DatabaseUsername=$(aws secretsmanager get-secret-value --secret-id /tf-playground/dev/database/credentials --region us-east-2 --query SecretString --output text | jq -r '.username'),DatabasePassword=$(aws secretsmanager get-secret-value --secret-id /tf-playground/dev/database/credentials --region us-east-2 --query SecretString --output text | jq -r '.password'),InstanceId=$(terraform output -raw webserver_instance_id),AutomationAssumeRole=$(aws iam get-role --role-name dev-ssm-automation-role --query 'Role.Arn' --output text)" \
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

## Prerequisites

### Required Tools

- Terraform >= 1.0.0
- AWS CLI configured with appropriate credentials
- `jq` installed locally (`sudo apt install jq` on Ubuntu/WSL)

### AWS Resources Required Before Terraform

1. **KMS Key and Alias**

   - Create a KMS key for encrypting sensitive data
   - Create an alias (e.g., `alias/tf-playground-dev-secrets`)

2. **AWS Secrets Manager Secret**

   - Create a secret for database credentials with the following structure:
     ```json
     {
       "username": "dbadmin",
       "password": "your-secure-password",
       "engine": "mysql",
       "host": "localhost",
       "port": 3306,
       "dbname": "tfplayground"
     }
     ```
   - Secret name: `/tf-playground/dev/database/credentials`

3. **SSH Key Pair**
   - Create an SSH key pair in AWS
   - Save the private key as `~/.ssh/tf-playground-dev.pem`
   - Set permissions: `chmod 400 ~/.ssh/tf-playground-dev.pem`

## Environment-Specific Commands

### Staging Environment

```bash
cd environments/staging
terraform apply -auto-approve

aws ssm start-automation-execution \
  --document-name "staging-database-automation" \
  --parameters "DatabaseEndpoint=$(terraform output -raw database_endpoint | sed 's/:3306$//'),DatabaseName=$(terraform output -raw database_name),DatabaseUsername=$(aws secretsmanager get-secret-value --secret-id /tf-playground/staging/database/credentials --region us-east-2 --query SecretString --output text | jq -r '.username'),DatabasePassword=$(aws secretsmanager get-secret-value --secret-id /tf-playground/staging/database/credentials --region us-east-2 --query SecretString --output text | jq -r '.password'),InstanceId=$(terraform output -raw webserver_instance_id),AutomationAssumeRole=$(aws iam get-role --role-name staging-ssm-automation-role --query 'Role.Arn' --output text)" \
  --region us-east-2
```

### Production Environment

```bash
cd environments/production
terraform apply -auto-approve

aws ssm start-automation-execution \
  --document-name "production-database-automation" \
  --parameters "DatabaseEndpoint=$(terraform output -raw database_endpoint | sed 's/:3306$//'),DatabaseName=$(terraform output -raw database_name),DatabaseUsername=$(aws secretsmanager get-secret-value --secret-id /tf-playground/production/database/credentials --region us-east-2 --query SecretString --output text | jq -r '.username'),DatabasePassword=$(aws secretsmanager get-secret-value --secret-id /tf-playground/production/database/credentials --region us-east-2 --query SecretString --output text | jq -r '.password'),InstanceId=$(terraform output -raw webserver_instance_id),AutomationAssumeRole=$(aws iam get-role --role-name production-ssm-automation-role --query 'Role.Arn' --output text)" \
  --region us-east-2
```

## Troubleshooting

### Common Issues

1. **jq not installed**: Install jq for JSON parsing: `sudo yum install -y jq` (Amazon Linux) or `sudo apt-get install jq` (Ubuntu)
2. **Permission errors**: Ensure your AWS credentials have appropriate SSM and Secrets Manager permissions
3. **Database connection**: Verify security groups allow EC2 to RDS communication

### Manual Database Setup (Alternative)

If SSM automation fails, you can SSH into the EC2 instance and run the commands manually:

```bash
# SSH into instance
ssh -i ~/.ssh/tf-playground-dev.pem ec2-user@<public-ip>

# Install MariaDB client
sudo yum install -y mariadb1011-client-utils

# Get database credentials from Secrets Manager
DB_CREDS=$(aws secretsmanager get-secret-value --secret-id /tf-playground/dev/database/credentials --region us-east-2 --query SecretString --output text)
DB_HOST=$(echo $DB_CREDS | jq -r '.host')
DB_USER=$(echo $DB_CREDS | jq -r '.username')
DB_PASS=$(echo $DB_CREDS | jq -r '.password')
DB_NAME=$(echo $DB_CREDS | jq -r '.dbname')

# Run the database setup manually
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME < /path/to/init.sql
```

## Security Notes

- Database credentials are stored in AWS Secrets Manager
- KMS key is used for encryption
- SSM automation uses least-privilege IAM policies
- All values are dynamically retrieved from Terraform outputs and Secrets Manager
- No hardcoded values in the automation process

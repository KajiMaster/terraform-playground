# Terraform Playground

A comprehensive Terraform playground for AWS infrastructure automation, featuring multi-environment deployment, CI/CD integration, and database bootstrapping with AWS Systems Manager (SSM).

## Features

- **Multi-Environment Support**: Dev, staging, and production environments with GitFlow workflow
- **SSM Database Bootstrap**: Automated database initialization using AWS Systems Manager
- **CI/CD Pipeline**: GitHub Actions workflow for automated deployments with OIDC authentication
- **Team Development**: Individual developer environments with conflict-free workflows
- **Modular Design**: Reusable Terraform modules for networking, compute, database, SSM, and OIDC
- **Secrets Management**: Secure credential handling with random suffixes to avoid deletion conflicts
- **Global Resources**: Centralized OIDC provider for GitHub Actions authentication

## Current State (Version 2)

The infrastructure includes:

- VPC with public and private subnets across two availability zones
- NAT Gateway for private subnet internet access
- RDS MySQL instance in private subnet
- EC2 instance in public subnet running a Flask web application
- IAM roles and policies for secure access to AWS services
- KMS encryption for sensitive data with random suffixes
- AWS Secrets Manager for database credentials
- SSM automation for database bootstrapping
- OIDC provider for GitHub Actions authentication
- CI/CD pipeline with automated plan/apply workflows

### Working Components

- ✅ Web application running on port 8080
- ✅ Database with sample contacts data
- ✅ Health check endpoint at `/health`
- ✅ Data endpoint at `/` returning JSON
- ✅ Secure database access through IAM roles
- ✅ Encrypted secrets management with random suffixes
- ✅ Automated database population via SSM
- ✅ CI/CD pipeline for staging deployments
- ✅ OIDC authentication for GitHub Actions

## Prerequisites

### AWS Resources Required Before Terraform

1. **SSH Key Pair**
   - Create an SSH key pair in AWS named `tf-playground-key`
   - Save the private key as `~/.ssh/tf-playground-key.pem`
   - Set appropriate permissions: `chmod 400 ~/.ssh/tf-playground-key.pem`

### Required Tools

- Terraform >= 1.0.0
- AWS CLI configured with appropriate credentials
- jq (for JSON parsing in automation commands)

## Project Structure

```
terraform-playground/
├── environments/          # Environment-specific configurations
│   ├── dev/              # Development environment (feature branches)
│   ├── staging/          # Staging environment (develop branch)
│   ├── production/       # Production environment (main branch)
│   └── global/           # Global resources (OIDC provider)
├── modules/              # Reusable Terraform modules
│   ├── compute/          # Compute resources (EC2, etc.)
│   │   └── webserver/    # Web server module with IAM roles
│   ├── database/         # Database resources (RDS)
│   ├── networking/       # Networking resources (VPC, etc.)
│   ├── secrets/          # Secrets management module
│   ├── ssm/              # SSM automation module
│   └── oidc/             # OIDC provider module
├── docs/                 # Documentation
└── .github/workflows/    # CI/CD workflows
```

## GitFlow Workflow

- **Feature branches**: Individual developer environments (dev)
- **Develop branch**: Staging environment with automated CI/CD
- **Main branch**: Production environment

## Deployment

### Development Environment

1. **Deploy Infrastructure**

   ```bash
   cd environments/dev
   terraform apply -var='key_name=tf-playground-key'
   ```

2. **Bootstrap Database**

   ```bash
   aws ssm start-automation-execution \
     --document-name "dev-database-automation" \
     --parameters "DatabaseEndpoint=$(terraform output -raw database_endpoint | sed 's/:3306$//'),DatabaseName=$(terraform output -raw database_name),DatabaseUsername=$(aws secretsmanager get-secret-value --secret-id /tf-playground/dev/database/credentials-$(terraform output -raw random_suffix) --region us-east-2 --query SecretString --output text | jq -r '.username'),DatabasePassword=$(aws secretsmanager get-secret-value --secret-id /tf-playground/dev/database/credentials-$(terraform output -raw random_suffix) --region us-east-2 --query SecretString --output text | jq -r '.password'),InstanceId=$(terraform output -raw webserver_instance_id),AutomationAssumeRole=$(aws iam get-role --role-name dev-ssm-automation-role --query 'Role.Arn' --output text)" \
     --region us-east-2
   ```

### Staging Environment

1. **Deploy Infrastructure**

   ```bash
   cd environments/staging
   terraform apply
   ```

2. **Bootstrap Database**

   ```bash
   aws ssm start-automation-execution --document-name "staging-database-automation" --parameters "DatabaseEndpoint=$(terraform output -raw database_endpoint | sed 's/:3306$//'),DatabaseName=$(terraform output -raw database_name),DatabaseUsername=$(aws secretsmanager get-secret-value --secret-id /tf-playground/staging/database/credentials-$(terraform output -raw random_suffix) --region us-east-2 --query SecretString --output text | jq -r '.username'),DatabasePassword=\"$(aws secretsmanager get-secret-value --secret-id /tf-playground/staging/database/credentials-$(terraform output -raw random_suffix) --region us-east-2 --query SecretString --output text | jq -r '.password')\",InstanceId=$(terraform output -raw webserver_instance_id),AutomationAssumeRole=$(aws iam get-role --role-name staging-ssm-automation-role --query 'Role.Arn' --output text)" --region us-east-2
   ```

3. **Verify Setup**

   - Check web application: `http://<webserver-public-ip>:8080`
   - Health check: `http://<webserver-public-ip>:8080/health`
   - Data endpoint: `http://<webserver-public-ip>:8080/` (should return JSON with contacts)

**Note**: The database bootstrap is fully automated using AWS SSM. No manual SSH or database setup is required. The automation handles special characters in passwords and creates sample data automatically.

## CI/CD Pipeline

The project includes automated CI/CD workflows:

- **Pull Request to Develop**: Runs `terraform plan` automatically
- **Merge to Develop**: Runs `terraform apply` for staging environment
- **OIDC Authentication**: Secure AWS access without stored credentials

## IAM Permissions

The project uses several IAM policies to manage access:

1. **Web Server Secrets Policy**
   - Allows access to Secrets Manager for database credentials
   - Permits KMS operations for decryption
   - Policy is attached to the EC2 instance role

2. **SSM Automation Policy**
   - Enables SSM automation execution
   - Allows database initialization commands
   - Policy is attached to the SSM automation role

3. **GitHub Actions Policy**
   - Enables Terraform operations via CI/CD
   - Uses OIDC for secure authentication
   - Policy is attached to the GitHub Actions role

## Security Notes

- Database credentials are stored in AWS Secrets Manager with random suffixes
- KMS keys are used for encryption with environment-specific naming
- RDS instances are in private subnets
- Security groups restrict access to necessary ports only
- IAM roles follow principle of least privilege
- OIDC authentication eliminates need for stored AWS credentials
- Random suffixes prevent deletion recovery window conflicts

## Troubleshooting

### Common Issues

1. **Secrets Manager "already scheduled for deletion" error**
   - This is prevented by random suffixes in secret names
   - If it occurs, wait for the deletion recovery window or use a different environment

2. **SSM automation syntax errors**
   - Fixed by using environment variables for password handling
   - Special characters in passwords are now properly escaped

3. **IAM role conflicts**
   - Ensure no duplicate role definitions between modules
   - Check for conflicts between `iam.tf` files and module roles

## Contributing

1. Create a feature branch for your changes
2. Make your changes and test in dev environment
3. Submit a pull request to develop branch
4. Ensure CI checks pass
5. Get review and approval
6. Merge to develop (auto-deploys to staging)
7. When ready, merge develop to main for production

## License

MIT License

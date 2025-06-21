# Terraform Playground

> **🎯 Mission Statement**: This is a comprehensive learning project designed to demonstrate enterprise-grade Infrastructure-as-Code capabilities. Built to showcase Terraform expertise, AWS cloud architecture, and CI/CD automation skills for career advancement and professional development. This is NOT a production system - it's a sophisticated playground for learning and skill demonstration.

A comprehensive Terraform playground for AWS infrastructure automation, featuring multi-environment deployment, CI/CD integration, and database bootstrapping with AWS Systems Manager (SSM).

## 🚀 What This Demonstrates

This project showcases real-world enterprise skills including:

- **Infrastructure as Code**: Complete AWS infrastructure defined in Terraform
- **CI/CD Automation**: GitHub Actions with OIDC authentication and automated deployments
- **Multi-Environment Management**: Dev, staging, production with GitFlow workflow
- **Security Best Practices**: IAM roles, KMS encryption, Secrets Manager, OIDC
- **Team Development**: Individual developer environments with conflict resolution
- **Database Automation**: SSM-based database bootstrapping and management
- **Modular Architecture**: Reusable Terraform modules for scalability
- **Cost Management**: Development environment lifecycle management

## 🎯 Active Development: Blue-Green Deployment

**Coming Soon**: Advanced blue-green deployment strategy with zero-downtime deployments, automated rollbacks, and production-grade deployment safety.

**What This Will Add**:
- Application Load Balancer with traffic switching
- Dual environment setup (blue/green) with auto-scaling
- Comprehensive health checks and deployment validation
- Automated rollback mechanisms
- Enhanced CI/CD pipeline with deployment safety

**Career Impact**: This will demonstrate advanced DevOps skills highly sought after in the job market, including zero-downtime deployments and production deployment safety.

📋 **Project Details**: See [`docs/blue-green-deployment-project.md`](docs/blue-green-deployment-project.md) for comprehensive planning and implementation details.

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

## Local Configuration Files

The following files are `.gitignore`d and need to be created locally:

### SSH Key File
- **Location**: `~/.ssh/tf-playground-key.pem`
- **Purpose**: SSH access to EC2 instances
- **Setup**: Download from AWS Console after creating key pair

### Environment Variables Files
Each environment has a `terraform.tfvars` file for local development:

- **`environments/dev/terraform.tfvars`** - Development environment variables
- **`environments/staging/terraform.tfvars`** - Staging environment variables  
- **`environments/production/terraform.tfvars`** - Production environment variables

**Example terraform.tfvars content:**
```hcl
key_name = "tf-playground-key"
```

**Note**: These files are not tracked by Git for security reasons. Create them locally for convenient development without needing `-var` flags.

**Additional Configuration**: Each environment also includes an `example.tfvars` file showing all available variables for reference.

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
   terraform apply
   ```

   **Note**: Uses `terraform.tfvars` for SSH key configuration. Create this file locally if it doesn't exist.

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

4. **SSH key not found errors**
   - Ensure `~/.ssh/tf-playground-key.pem` exists and has correct permissions (400)
   - Verify the key pair name in AWS matches `tf-playground-key`
   - Check that `terraform.tfvars` contains the correct `key_name` value

## Contributing

1. Create a feature branch for your changes
2. Make your changes and test in dev environment
3. Submit a pull request to develop branch
4. Ensure CI checks pass
5. Get review and approval
6. Merge to develop (auto-deploys to staging)
7. When ready, merge develop to main for production

## Future Development

See [docs/future-roadmap.md](docs/future-roadmap.md) for planned improvements, potential scenarios, and questions for future development sessions. This roadmap helps maintain focus while ensuring we don't lose track of important considerations.

## License

MIT License

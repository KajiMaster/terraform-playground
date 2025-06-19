# Terraform Playground

A comprehensive Terraform playground for AWS infrastructure automation, featuring multi-environment deployment, CI/CD integration, and database bootstrapping with AWS Systems Manager (SSM).

## Features

- **Multi-Environment Support**: Dev, staging, and production environments
- **SSM Database Bootstrap**: Automated database initialization using AWS Systems Manager
- **CI/CD Pipeline**: GitHub Actions workflow for automated deployments
- **Team Development**: Individual developer environments with conflict-free workflows
- **Modular Design**: Reusable Terraform modules for networking, compute, database, and SSM

## Current State (Version 1)

The infrastructure includes:

- VPC with public and private subnets across two availability zones
- NAT Gateway for private subnet internet access
- RDS MySQL instance in private subnet
- EC2 instance in public subnet running a Flask web application
- IAM roles and policies for secure access to AWS services
- KMS encryption for sensitive data
- AWS Secrets Manager for database credentials

### Working Components

- ✅ Web application running on port 8080
- ✅ Database with sample contacts data
- ✅ Health check endpoint at `/health`
- ✅ Data endpoint at `/` returning JSON
- ✅ Secure database access through IAM roles
- ✅ Encrypted secrets management

## Prerequisites

### AWS Resources Required Before Terraform

1. **KMS Key and Alias**

   - Create a KMS key for encrypting sensitive data
   - Create an alias for the key (e.g., `alias/tf-playground-dev-secrets`)
   - Note: The key will be imported as a data source in Terraform

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
   - Secret name should follow the pattern: `/tf-playground/<environment>/database/credentials`
   - Note: The secret will be imported as a data source in Terraform

3. **SSH Key Pair**
   - Create an SSH key pair in AWS
   - Save the private key as `~/.ssh/tf-playground-dev.pem`
   - Set appropriate permissions: `chmod 400 ~/.ssh/tf-playground-dev.pem`

### Required Tools

- Terraform >= 1.0.0
- AWS CLI configured with appropriate credentials
- MySQL/MariaDB client (for database initialization)

## Project Structure

```
terraform-playground/
├── environments/          # Environment-specific configurations
│   ├── dev/              # Development environment
│   ├── stage/            # Staging environment (to be added)
│   └── prod/             # Production environment (to be added)
├── modules/              # Reusable Terraform modules
│   ├── compute/          # Compute resources (EC2, etc.)
│   │   └── webserver/    # Web server module with IAM roles
│   ├── database/         # Database resources (RDS)
│   ├── networking/       # Networking resources (VPC, etc.)
│   └── secrets/          # Secrets management module
├── scripts/              # Utility scripts
│   └── setup-remote-state.sh  # Creates S3 bucket and DynamoDB table for Terraform state
└── docs/                 # Documentation
```

## Deployment

1. **Deploy Infrastructure**

   ```bash
   cd environments/dev
   terraform apply -auto-approve
   ```

2. **Bootstrap Database**

   ```bash
   aws ssm start-automation-execution \
     --document-name "dev-database-automation" \
     --parameters "DatabaseEndpoint=$(terraform output -raw database_endpoint | sed 's/:3306$//'),DatabaseName=$(terraform output -raw database_name),DatabaseUsername=$(aws secretsmanager get-secret-value --secret-id /tf-playground/dev/database/credentials --region us-east-2 --query SecretString --output text | jq -r '.username'),DatabasePassword=$(aws secretsmanager get-secret-value --secret-id /tf-playground/dev/database/credentials --region us-east-2 --query SecretString --output text | jq -r '.password'),InstanceId=$(terraform output -raw webserver_instance_id),AutomationAssumeRole=$(aws iam get-role --role-name dev-ssm-automation-role --query 'Role.Arn' --output text)" \
     --region us-east-2
   ```

3. **Verify Setup**

   - Check web application: `http://<webserver-public-ip>:8080`
   - Health check: `http://<webserver-public-ip>:8080/health`
   - Data endpoint: `http://<webserver-public-ip>:8080/` (should return JSON with contacts)

**Note**: The database bootstrap is fully automated using AWS SSM. No manual SSH or database setup is required. See `docs/database-bootstrap.md` for detailed documentation.

## IAM Permissions

The project uses several IAM policies to manage access:

1. **Web Server Secrets Policy**

   - Allows access to Secrets Manager for database credentials
   - Permits KMS operations for decryption
   - Policy is attached to the EC2 instance role

2. **Web Server RDS Policy**
   - Enables RDS database connection
   - Allows instance to describe RDS resources
   - Policy is attached to the EC2 instance role

## Security Notes

- Database credentials are stored in AWS Secrets Manager
- KMS key is used for encryption
- RDS instance is in a private subnet
- Security groups restrict access to necessary ports only
- IAM roles follow principle of least privilege

## Contributing

1. Create a new branch for your changes
2. Make your changes
3. Submit a pull request
4. Ensure CI checks pass
5. Get review and approval
6. Merge to main

## License

MIT License

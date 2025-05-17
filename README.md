# Terraform Playground

A learning project focused on Terraform best practices, modular infrastructure, and environment management. This project sets up a web application infrastructure with an EC2 instance in a public subnet and an RDS MySQL database in a private subnet.

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
│   ├── init-database.sh  # Database initialization script
│   └── sql/             # SQL scripts
│       ├── init.sql     # Initial schema and data
│       └── add_contacts.sql  # Additional sample data
└── docs/                 # Documentation
```

## Deployment

1. **Initial Setup**

   ```bash
   cd environments/dev
   terraform init
   ```

2. **Review and Apply**

   ```bash
   terraform plan
   terraform apply
   ```

3. **Post-Deployment Steps**

   a. **Install MariaDB Client** (if not already installed via user_data)

   ```bash
   sudo yum install -y mariadb1011-client-utils
   ```

   b. **Transfer Initialization Files**

   ```bash
   scp -i ~/.ssh/tf-playground-dev.pem scripts/init-database.sh scripts/sql/init.sql ec2-user@<webserver-ip>:/home/ec2-user/
   ```

   c. **Set Up Directory Structure**

   ```bash
   mkdir -p /home/ec2-user/sql
   mv /home/ec2-user/init.sql /home/ec2-user/sql/
   chmod +x /home/ec2-user/init-database.sh
   ```

   d. **Initialize Database**

   ```bash
   ./init-database.sh dev
   ```

   e. **Add Additional Contacts** (Optional)

   ```bash
   scp -i ~/.ssh/tf-playground-dev.pem scripts/sql/add_contacts.sql ec2-user@<webserver-ip>:/home/ec2-user/sql/
   mysql -h <rds-endpoint> -u dbadmin -p"<password>" tfplayground < /home/ec2-user/sql/add_contacts.sql
   ```

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

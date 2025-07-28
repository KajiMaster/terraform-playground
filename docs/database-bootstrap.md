# Database Bootstrap Documentation

## 🎯 Overview

This document describes the automated database bootstrapping process using AWS Systems Manager (SSM) automation for ASG environments and ECS Exec for ECS environments. The process creates database tables and populates them with sample data automatically.

## 🚀 One-Liner Database Bootstrap Commands

### Development Environment (ASG)

```bash
cd environments/dev

# Bootstrap database with sample data (one-liner)
aws ssm start-automation-execution \
  --document-name "dev-database-automation" \
  --parameters \
    "DatabaseEndpoint=$(terraform output -raw database_endpoint | sed 's/:3306$//'),\
    DatabaseName=$(terraform output -raw database_name),\
    DatabaseUsername=$(aws secretsmanager get-secret-value --secret-id $(terraform output -raw secret_name) --region us-east-2 --query SecretString --output text | jq -r '.username'),\
    DatabasePassword=\"$(aws secretsmanager get-secret-value --secret-id $(terraform output -raw secret_name) --region us-east-2 --query SecretString --output text | jq -r '.password')\",\
    InstanceId=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $(terraform output -raw blue_asg_name) --region us-east-2 --query 'AutoScalingGroups[0].Instances[0].InstanceId' --output text),\
    AutomationAssumeRole=$(terraform output -raw ssm_automation_role_arn)" \
  --region us-east-2
```

### Staging Environment (ECS)

```bash
cd environments/staging

# Bootstrap database with sample data (one-liner)
./ecs-database-bootstrap-oneliner.sh
```

### Production Environment (ASG)

```bash
cd environments/production

# Bootstrap database with sample data (one-liner)
aws ssm start-automation-execution \
  --document-name "production-database-automation" \
  --parameters \
    "DatabaseEndpoint=$(terraform output -raw database_endpoint | sed 's/:3306$//'),\
    DatabaseName=$(terraform output -raw database_name),\
    DatabaseUsername=tfplayground_user,\
    DatabasePassword=\"$(aws secretsmanager get-secret-value --secret-id /tf-playground/all/db-pword --region us-east-2 --query SecretString --output text)\",\
    InstanceId=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $(terraform output -raw blue_asg_name) --region us-east-2 --query 'AutoScalingGroups[0].Instances[0].InstanceId' --output text),\
    AutomationAssumeRole=$(terraform output -raw ssm_automation_role_arn)" --region us-east-2
```

## 🔍 How It Works

### ASG Environment Process Overview
1. **SSM Automation** gets the InstanceID of an EC2 instance in the blue ASG
2. **Injects commands** directly into that instance via AWS Systems Manager
3. **The instance runs** the database setup scripts locally
4. **Connects to RDS** from that instance to create tables and insert data

### ECS Environment Process Overview
1. **ECS Exec** connects to a running ECS task in the blue service
2. **Creates SQL file** in the container with table creation and data insertion commands
3. **Executes SQL** using MySQL client tools installed in the container
4. **Connects to RDS** from within the ECS task to create tables and insert data

### What Happens on the EC2 Instance (ASG)
```bash
# SSM sends these commands to the instance:
yum install -y mariadb1011-client-utils  # Install MySQL client
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME  # Connect to RDS
# Then runs SQL commands to create tables and insert sample data
```

### What Happens in the ECS Container
```bash
# ECS Exec creates a SQL file in the container:
cat > /tmp/bootstrap-contacts.sql << 'EOF'
CREATE TABLE IF NOT EXISTS contacts (...);
INSERT INTO contacts (...) VALUES (...);
EOF

# Then executes the SQL file:
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME < /tmp/bootstrap-contacts.sql
```

### Database Schema Created
- **Table**: `contacts`
- **Columns**: 
  - `id` (auto-increment primary key)
  - `name` (VARCHAR 100)
  - `email` (VARCHAR 100, unique)
  - `phone` (VARCHAR 20)
  - `created_at` (TIMESTAMP)

### Sample Data Inserted
- John Doe (john.doe@example.com)
- Jane Smith (jane.smith@example.com)
- Bob Johnson (bob.johnson@example.com)
- Alice Brown (alice.brown@example.com)
- Charlie Wilson (charlie.wilson@example.com)

## 📋 Usage Instructions

1. **Navigate to the environment directory**:
   ```bash
   cd environments/[dev|staging|production]
   ```

2. **Run the appropriate one-liner** for your environment

3. **Monitor the automation** in AWS Systems Manager console (ASG) or check ECS task logs (ECS)

4. **Verify database population** by accessing the web application

## 🔧 Troubleshooting

### Common Issues

1. **"Output not found" errors**
   - Ensure you've run `terraform apply` to create the outputs
   - Check that you're in the correct environment directory

2. **"No instances found" in ASG**
   - Verify the blue ASG has at least one running instance
   - Check ASG health and scaling policies

3. **"No ECS tasks found"**
   - Verify the ECS service is running and has tasks
   - Check ECS service health and desired count

4. **Database connection failures**
   - Verify RDS instance is available
   - Check security group rules allow traffic from ASG instances or ECS tasks

5. **SSM automation failures**
   - Check IAM permissions for the SSM automation role
   - Verify the automation document exists in the correct region

6. **ECS Exec failures**
   - Ensure ECS Exec is enabled on the task definition
   - Check IAM permissions for ECS Exec
   - Verify the container has MySQL client tools installed

## 🎯 Success Indicators

- **SSM Automation Status**: "Success" in AWS Systems Manager console (ASG)
- **ECS Exec Output**: Shows contact count of 5 (ECS)
- **Database Records**: 5 contacts visible in the web application
- **Application Response**: JSON data returned at the application URL
- **Health Check**: `/health` endpoint returns "healthy" status

## 📚 Related Documentation

- [Blue-Green Deployment Project](../docs/blue-green-deployment-project.md)
- [SSM Module Documentation](../../modules/ssm/README.md)
- [Database Module Documentation](../../modules/database/README.md)
- [ECS Module Documentation](../../modules/ecs/README.md)
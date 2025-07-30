terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# SSM Automation Document for database initialization
resource "aws_ssm_document" "database_automation" {
  name            = "${var.environment}-database-automation"
  document_type   = "Automation"
  document_format = "YAML"

  content = <<DOC
schemaVersion: '0.3'
assumeRole: '{{ AutomationAssumeRole }}'
description: 'Automate database initialization with schema and sample data'
parameters:
  DatabaseEndpoint:
    type: String
    description: RDS database endpoint
  DatabaseName:
    type: String
    description: Database name
  DatabaseUsername:
    type: String
    description: Database username
  DatabasePassword:
    type: String
    description: Database password
  InstanceId:
    type: String
    description: EC2 instance ID to run commands on
  AutomationAssumeRole:
    type: String
    description: IAM role ARN for automation execution
mainSteps:
- name: installDependencies
  action: 'aws:runCommand'
  inputs:
    DocumentName: AWS-RunShellScript
    InstanceIds:
    - '{{ InstanceId }}'
    Parameters:
      commands:
      - |
        #!/bin/bash
        set -e
        
        # Update system packages
        yum update -y
        
        # Install MariaDB client if not already installed
        if ! command -v mysql &> /dev/null; then
            yum install -y mariadb1011-client-utils
        fi
        
        echo "Dependencies installed successfully"
- name: createDatabaseSchema
  action: 'aws:runCommand'
  inputs:
    DocumentName: AWS-RunShellScript
    InstanceIds:
    - '{{ InstanceId }}'
    Parameters:
      commands:
      - |
        #!/bin/bash
        set -e
        
        # Set environment variables to avoid shell escaping issues
        export DB_HOST="{{ DatabaseEndpoint }}"
        export DB_USER="{{ DatabaseUsername }}"
        export DB_PASS="{{ DatabasePassword }}"
        export DB_NAME="{{ DatabaseName }}"
        
        # Create database schema using environment variables
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" << 'EOF'
        CREATE TABLE IF NOT EXISTS contacts (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            email VARCHAR(100) NOT NULL UNIQUE,
            phone VARCHAR(20),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        EOF
        
        echo "Database schema created successfully"
- name: insertSampleData
  action: 'aws:runCommand'
  inputs:
    DocumentName: AWS-RunShellScript
    InstanceIds:
    - '{{ InstanceId }}'
    Parameters:
      commands:
      - |
        #!/bin/bash
        set -e
        
        # Set environment variables to avoid shell escaping issues
        export DB_HOST="{{ DatabaseEndpoint }}"
        export DB_USER="{{ DatabaseUsername }}"
        export DB_PASS="{{ DatabasePassword }}"
        export DB_NAME="{{ DatabaseName }}"
        
        # Insert sample data using environment variables
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" << 'EOF'
        INSERT IGNORE INTO contacts (name, email, phone) VALUES
        ('John Doe', 'john.doe@example.com', '+1-555-0101'),
        ('Jane Smith', 'jane.smith@example.com', '+1-555-0102'),
        ('Bob Johnson', 'bob.johnson@example.com', '+1-555-0103'),
        ('Alice Brown', 'alice.brown@example.com', '+1-555-0104'),
        ('Charlie Wilson', 'charlie.wilson@example.com', '+1-555-0105');
        EOF
        
        echo "Sample data inserted successfully"
- name: verifyDatabaseSetup
  action: 'aws:runCommand'
  inputs:
    DocumentName: AWS-RunShellScript
    InstanceIds:
    - '{{ InstanceId }}'
    Parameters:
      commands:
      - |
        #!/bin/bash
        set -e
        
        # Set environment variables to avoid shell escaping issues
        export DB_HOST="{{ DatabaseEndpoint }}"
        export DB_USER="{{ DatabaseUsername }}"
        export DB_PASS="{{ DatabasePassword }}"
        export DB_NAME="{{ DatabaseName }}"
        
        # Verify the setup using environment variables
        COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -s -N -e "SELECT COUNT(*) FROM contacts;")
        echo "Database setup complete. Found $COUNT contacts in the database."
DOC

  tags = {
    Name        = "${var.environment}-database-automation-doc"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# IAM Role for SSM Automation execution
resource "aws_iam_role" "ssm_automation" {
  name = "${var.environment}-ssm-automation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-ssm-automation-role"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# IAM Policy for SSM Automation execution
resource "aws_iam_policy" "ssm_automation" {
  name        = "${var.environment}-ssm-automation-policy"
  description = "Policy for SSM automation execution"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:StartAutomationExecution",
          "ssm:GetAutomationExecution",
          "ssm:DescribeAutomationExecutions"
        ]
        Resource = [
          aws_ssm_document.database_automation.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:ListCommandInvocations",
          "ssm:DescribeInstanceInformation"
        ]
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:DescribeInstanceInformation"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:ListCommands",
          "ssm:ListCommandInvocations"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}::document/AWS-RunShellScript",
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.ssm_automation.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::aws:role/aws-service-role/ssm.amazonaws.com/AWSServiceRoleForAmazonSSM"
        ]
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-ssm-automation-policy"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "ssm_automation" {
  role       = aws_iam_role.ssm_automation.name
  policy_arn = aws_iam_policy.ssm_automation.arn
}

# Get current region and account ID
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}


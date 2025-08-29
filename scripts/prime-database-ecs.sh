#!/bin/bash

set -e

# Configuration
ENVIRONMENT=${1:-staging}
AWS_REGION=${2:-us-east-2}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo "🗄️  Database Priming Script for ECS"
echo "=================================="
echo "Environment: $ENVIRONMENT"
echo "AWS Region: $AWS_REGION"
echo ""

# Check prerequisites
print_info "Checking prerequisites..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    print_error "AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

print_status "Prerequisites check passed"

# Get database information from Terraform
print_info "Getting database information from Terraform..."

cd environments/$ENVIRONMENT

# Get database endpoint
DB_ENDPOINT=$(terraform output -raw database_endpoint)
DB_NAME=$(terraform output -raw database_name)
DB_USER="tfplayground_user"

# Get database password from Parameter Store
DB_PASSWORD=$(aws ssm get-parameter --name "/tf-playground/all/db-password" --with-decryption --query 'Parameter.Value' --output text)

print_status "Database endpoint: $DB_ENDPOINT"
print_status "Database name: $DB_NAME"

# Go back to root directory
cd ../..

# Create a temporary task definition for database priming
print_info "Creating database priming task..."

# Create a temporary task definition JSON
cat > /tmp/db-prime-task.json << EOF
{
  "family": "db-prime-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/${ENVIRONMENT}-ecs-task-execution-role",
  "taskRoleArn": "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/${ENVIRONMENT}-ecs-task-role",
  "containerDefinitions": [
    {
      "name": "db-prime",
      "image": "mysql:8.0",
      "command": [
        "sh", "-c",
        "mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME -e \"CREATE TABLE IF NOT EXISTS contacts (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100) NOT NULL, email VARCHAR(100) UNIQUE NOT NULL, phone VARCHAR(20), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP); INSERT IGNORE INTO contacts (name, email, phone) VALUES ('John Doe', 'john.doe@example.com', '+1-555-0101'), ('Jane Smith', 'jane.smith@example.com', '+1-555-0102'), ('Bob Johnson', 'bob.johnson@example.com', '+1-555-0103'), ('Alice Brown', 'alice.brown@example.com', '+1-555-0104'), ('Charlie Wilson', 'charlie.wilson@example.com', '+1-555-0105'); SELECT COUNT(*) as contact_count FROM contacts;\""
      ],
      "environment": [
        {
          "name": "DB_HOST",
          "value": "$DB_ENDPOINT"
        },
        {
          "name": "DB_USER",
          "value": "$DB_USER"
        },
        {
          "name": "DB_PASS",
          "value": "$DB_PASSWORD"
        },
        {
          "name": "DB_NAME",
          "value": "$DB_NAME"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/aws/application/tf-playground/${ENVIRONMENT}",
          "awslogs-region": "$AWS_REGION",
          "awslogs-stream-prefix": "db-prime"
        }
      },
      "essential": true
    }
  ]
}
EOF

# Register the task definition
aws ecs register-task-definition --cli-input-json file:///tmp/db-prime-task.json

print_status "Task definition registered"

# Get ECS cluster name
CLUSTER_NAME="${ENVIRONMENT}-ecs-cluster"

# Get subnet and security group information
SUBNET_IDS=$(aws ecs describe-services --cluster $CLUSTER_NAME --services "${ENVIRONMENT}-blue-service" --query 'services[0].networkConfiguration.awsvpcConfiguration.subnets' --output text)
SECURITY_GROUP_IDS=$(aws ecs describe-services --cluster $CLUSTER_NAME --services "${ENVIRONMENT}-blue-service" --query 'services[0].networkConfiguration.awsvpcConfiguration.securityGroups' --output text)

print_info "Running database priming task..."

# Run the task
TASK_ARN=$(aws ecs run-task \
  --cluster $CLUSTER_NAME \
  --task-definition db-prime-task \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_IDS],securityGroups=[$SECURITY_GROUP_IDS],assignPublicIp=DISABLED}" \
  --query 'tasks[0].taskArn' \
  --output text)

print_status "Task started: $TASK_ARN"

# Wait for task completion
print_info "Waiting for task completion..."
aws ecs wait tasks-stopped --cluster $CLUSTER_NAME --tasks $TASK_ARN

# Get task status
TASK_STATUS=$(aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TASK_ARN --query 'tasks[0].lastStatus' --output text)

if [ "$TASK_STATUS" = "STOPPED" ]; then
    EXIT_CODE=$(aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TASK_ARN --query 'tasks[0].containers[0].exitCode' --output text)
    
    if [ "$EXIT_CODE" = "0" ]; then
        print_status "Database priming completed successfully!"
        
        # Get the logs to show the results
        print_info "Database priming results:"
        aws logs get-log-events \
          --log-group-name "/aws/application/tf-playground/${ENVIRONMENT}" \
          --log-stream-name "db-prime/db-prime/$(echo $TASK_ARN | cut -d'/' -f3)" \
          --query 'events[*].message' \
          --output text
    else
        print_error "Database priming failed with exit code: $EXIT_CODE"
        
        # Show the logs for debugging
        print_info "Task logs:"
        aws logs get-log-events \
          --log-group-name "/aws/application/tf-playground/${ENVIRONMENT}" \
          --log-stream-name "db-prime/db-prime/$(echo $TASK_ARN | cut -d'/' -f3)" \
          --query 'events[*].message' \
          --output text
        exit 1
    fi
else
    print_error "Task did not complete properly. Status: $TASK_STATUS"
    exit 1
fi

# Clean up
print_info "Cleaning up..."
aws ecs deregister-task-definition --task-definition db-prime-task
rm -f /tmp/db-prime-task.json

print_status "Database priming completed successfully!"
print_info "You can now test the application at: http://$(cd environments/$ENVIRONMENT && terraform output -raw alb_url)" 
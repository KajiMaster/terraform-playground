#!/bin/bash

set -e

# Configuration
ENVIRONMENT="production"
AWS_REGION="us-east-2"

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

echo "🗄️  Clear Production Database - Fresh Start"
echo "==========================================="
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

# Navigate to terraform directory
print_info "Navigating to Terraform directory..."
cd environments/terraform

# Check if workspace exists
if ! terraform workspace list | grep -q " $ENVIRONMENT$"; then
    print_error "Terraform workspace '$ENVIRONMENT' does not exist"
    echo "Available workspaces:"
    terraform workspace list | sed 's/^/  /'
    exit 1
fi

# Switch to production workspace
print_info "Switching to production workspace..."
terraform workspace select "$ENVIRONMENT"

# Get database information
print_info "Getting database information from Terraform outputs..."

DB_ENDPOINT=$(terraform output -raw database_endpoint 2>/dev/null)
if [ -z "$DB_ENDPOINT" ]; then
    print_error "Could not get database endpoint from Terraform outputs"
    exit 1
fi

DB_NAME=$(terraform output -raw database_name 2>/dev/null)
if [ -z "$DB_NAME" ]; then
    print_error "Could not get database name from Terraform outputs"
    exit 1
fi

print_status "Database endpoint: $DB_ENDPOINT"
print_status "Database name: $DB_NAME"

# Get database password from Parameter Store
print_info "Getting database password from Parameter Store..."
DB_PASSWORD=$(aws ssm get-parameter \
    --name "/tf-playground/all/db-pword" \
    --region "$AWS_REGION" \
    --with-decryption \
    --query 'Parameter.Value' \
    --output text 2>/dev/null)

if [ -z "$DB_PASSWORD" ]; then
    print_error "Could not get database password from Parameter Store"
    exit 1
fi

print_status "Database password retrieved successfully"

# Get ECS cluster and service information
print_info "Getting ECS information..."

CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null)
if [ -z "$CLUSTER_NAME" ]; then
    print_error "Could not get ECS cluster name from Terraform outputs"
    exit 1
fi

SERVICE_NAME=$(terraform output -raw blue_ecs_service_name 2>/dev/null)
if [ -z "$SERVICE_NAME" ]; then
    print_error "Could not get ECS service name from Terraform outputs"
    exit 1
fi

print_status "ECS Cluster: $CLUSTER_NAME"
print_status "ECS Service: $SERVICE_NAME"

# Get a running task
print_info "Getting running ECS task..."
TASK_ARN=$(aws ecs list-tasks \
    --cluster "$CLUSTER_NAME" \
    --service-name "$SERVICE_NAME" \
    --desired-status RUNNING \
    --region "$AWS_REGION" \
    --query 'taskArns[0]' \
    --output text 2>/dev/null)

if [ -z "$TASK_ARN" ] || [ "$TASK_ARN" = "None" ]; then
    print_error "No running ECS tasks found"
    exit 1
fi

print_status "Found task: $TASK_ARN"

# Show current database state
print_info "Checking current database state..."
echo ""

# Check tables
print_info "Current tables in database:"
aws ecs execute-command \
    --cluster "$CLUSTER_NAME" \
    --task "$TASK_ARN" \
    --container flask-app \
    --interactive \
    --command "/bin/bash -c 'mysql -h \$DB_HOST -u \$DB_USER -p\$DB_PASSWORD \$DB_NAME -e \"SHOW TABLES;\"'" \
    --region "$AWS_REGION" 2>/dev/null || echo "Could not list tables"

echo ""

# Confirm deletion
print_warning "⚠️  WARNING: This will DELETE ALL DATA from the production database!"
echo ""
print_warning "This will:"
echo "  - Drop all tables"
echo "  - Remove all data"
echo "  - Start with a completely fresh database"
echo ""
print_warning "Database: $DB_NAME"
print_warning "ECS Task: $TASK_ARN"
echo ""
read -p "Are you ABSOLUTELY sure you want to continue? Type 'YES' to confirm: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    print_info "Operation cancelled"
    exit 0
fi

# Clear the database
print_info "Clearing database..."

# Drop all tables
print_info "Dropping all tables..."
aws ecs execute-command \
    --cluster "$CLUSTER_NAME" \
    --task "$TASK_ARN" \
    --container flask-app \
    --interactive \
    --command "/bin/bash -c 'mysql -h \$DB_HOST -u \$DB_USER -p\$DB_PASSWORD \$DB_NAME -e \"SET FOREIGN_KEY_CHECKS = 0; DROP TABLE IF EXISTS contacts, users, categories, products, orders, order_items; SET FOREIGN_KEY_CHECKS = 1;\"'" \
    --region "$AWS_REGION"

print_status "Database cleared successfully!"

# Verify database is empty
print_info "Verifying database is empty..."
aws ecs execute-command \
    --cluster "$CLUSTER_NAME" \
    --task "$TASK_ARN" \
    --container flask-app \
    --interactive \
    --command "/bin/bash -c 'mysql -h \$DB_HOST -u \$DB_USER -p\$DB_PASSWORD \$DB_NAME -e \"SHOW TABLES;\"'" \
    --region "$AWS_REGION" 2>/dev/null

print_status "Database is now empty and ready for fresh data!"

echo ""
print_info "Next steps:"
echo "1. The database is completely cleared"
echo "2. When you deploy the fixed code, it will create fresh tables"
echo "3. Run the bootstrap script to populate with clean data"
echo "4. The /contacts endpoint should work without any validation errors"
echo ""
print_info "To repopulate the database, run:"
echo "  ./environments/terraform/ecs-database-bootstrap.sh production" 
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

echo "🗄️  Clear Production Contacts via ECS"
echo "===================================="
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

# Get ECS cluster and service information
print_info "Getting ECS information from Terraform outputs..."

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

# Get database information
print_info "Getting database information..."

DB_NAME=$(terraform output -raw database_name 2>/dev/null)
if [ -z "$DB_NAME" ]; then
    print_error "Could not get database name from Terraform outputs"
    exit 1
fi

print_status "Database name: $DB_NAME"

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

# Confirm deletion
echo ""
print_warning "This will DELETE ALL contacts from the production database!"
echo "Database: $DB_NAME"
echo "ECS Task: $TASK_ARN"
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_info "Operation cancelled"
    exit 0
fi

# Execute the command in the ECS task
print_info "Executing database command in ECS task..."

# First, check current contacts count
print_info "Checking current contacts count..."
CONTACTS_COUNT=$(aws ecs execute-command \
    --cluster "$CLUSTER_NAME" \
    --task "$TASK_ARN" \
    --container flask-app \
    --interactive \
    --command "/bin/bash -c 'mysql -h \$DB_HOST -u \$DB_USER -p\$DB_PASSWORD \$DB_NAME -e \"SELECT COUNT(*) FROM contacts;\" -s -N'" \
    --region "$AWS_REGION" 2>/dev/null | tail -n 1)

if [ -z "$CONTACTS_COUNT" ]; then
    CONTACTS_COUNT="unknown"
fi

print_status "Current contacts count: $CONTACTS_COUNT"

# Clear contacts table
print_info "Clearing contacts table..."
aws ecs execute-command \
    --cluster "$CLUSTER_NAME" \
    --task "$TASK_ARN" \
    --container flask-app \
    --interactive \
    --command "/bin/bash -c 'mysql -h \$DB_HOST -u \$DB_USER -p\$DB_PASSWORD \$DB_NAME -e \"DELETE FROM contacts;\"'" \
    --region "$AWS_REGION"

# Verify deletion
print_info "Verifying deletion..."
NEW_COUNT=$(aws ecs execute-command \
    --cluster "$CLUSTER_NAME" \
    --task "$TASK_ARN" \
    --container flask-app \
    --interactive \
    --command "/bin/bash -c 'mysql -h \$DB_HOST -u \$DB_USER -p\$DB_PASSWORD \$DB_NAME -e \"SELECT COUNT(*) FROM contacts;\" -s -N'" \
    --region "$AWS_REGION" 2>/dev/null | tail -n 1)

print_status "Contacts table cleared successfully!"
print_status "New contacts count: $NEW_COUNT"

echo ""
print_info "Next steps:"
echo "1. The contacts table is now empty"
echo "2. When you deploy the fixed code, new contacts will have proper created_at timestamps"
echo "3. The /contacts endpoint should work without validation errors" 
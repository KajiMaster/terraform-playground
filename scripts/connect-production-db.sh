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

echo "🗄️  Production Database Connection Script"
echo "========================================"
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

# Get database information from Terraform outputs
print_info "Getting database information from Terraform outputs..."

# Get database endpoint
DB_ENDPOINT=$(terraform output -raw database_endpoint 2>/dev/null)
if [ -z "$DB_ENDPOINT" ]; then
    print_error "Could not get database endpoint from Terraform outputs"
    echo "Make sure the environment is deployed and has outputs available"
    exit 1
fi

# Strip port from database endpoint (MySQL expects just hostname)
DB_HOST=$(echo "$DB_ENDPOINT" | cut -d: -f1)

# Get database name
DB_NAME=$(terraform output -raw database_name 2>/dev/null)
if [ -z "$DB_NAME" ]; then
    print_error "Could not get database name from Terraform outputs"
    exit 1
fi

# Get database username
DB_USER=$(terraform output -raw db_username 2>/dev/null)
if [ -z "$DB_USER" ]; then
    DB_USER="tfplayground_user"  # Fallback
fi

print_status "Database endpoint: $DB_ENDPOINT"
print_status "Database host: $DB_HOST"
print_status "Database name: $DB_NAME"
print_status "Database user: $DB_USER"

# Get database password from Parameter Store
print_info "Getting database password from Parameter Store..."
DB_PASSWORD=$(aws ssm get-parameter \
    --name "/tf-playground/all/db-password" \
    --region "$AWS_REGION" \
    --with-decryption \
    --query 'Parameter.Value' \
    --output text 2>/dev/null)

if [ -z "$DB_PASSWORD" ]; then
    print_error "Could not get database password from Parameter Store"
    exit 1
fi

print_status "Database password retrieved successfully"

# Display connection information
echo ""
print_info "Database Connection Information:"
echo "  Host: $DB_HOST"
echo "  Port: 3306"
echo "  Database: $DB_NAME"
echo "  Username: $DB_USER"
echo "  Password: [retrieved from Parameter Store]"
echo ""

# Test connection
print_info "Testing database connection..."
if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SELECT 1;" >/dev/null 2>&1; then
    print_status "Database connection successful!"
else
    print_error "Database connection failed"
    exit 1
fi

# Interactive mode
echo ""
print_info "Starting interactive MySQL session..."
echo "Type 'exit' to quit"
echo ""

# Start MySQL session
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" 
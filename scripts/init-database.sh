#!/bin/bash

# Database initialization script for tf-playground
# This script automates the process of initializing and populating the database
# Prerequisites:
# - SSH key at ~/.ssh/tf-playground-dev.pem
# - SQL files in scripts/sql/ directory
# - AWS credentials configured

set -e  # Exit on any error

# Configuration
EC2_USER="ec2-user"
SSH_KEY="~/.ssh/tf-playground-dev.pem"
SQL_DIR="scripts/sql"
REMOTE_DIR="/home/ec2-user"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is required but not installed. Please install it first."
        exit 1
    fi
}

# Check prerequisites
print_status "Checking prerequisites..."
check_command "ssh"
check_command "scp"
check_command "mysql"

# Get EC2 public IP from terraform state
print_status "Getting EC2 public IP from terraform state..."
EC2_IP=$(terraform output -state=environments/dev/terraform.tfstate -raw webserver_public_ip)
if [ -z "$EC2_IP" ]; then
    print_error "Could not get EC2 public IP from terraform state"
    exit 1
fi
print_status "EC2 IP: $EC2_IP"

# Get database endpoint from terraform state
print_status "Getting database endpoint from terraform state..."
DB_ENDPOINT=$(terraform output -state=environments/dev/terraform.tfstate -raw database_endpoint)
if [ -z "$DB_ENDPOINT" ]; then
    print_error "Could not get database endpoint from terraform state"
    exit 1
fi
print_status "Database endpoint: $DB_ENDPOINT"

# Get database credentials from terraform state
print_status "Getting database credentials from terraform state..."
DB_USER=$(terraform output -state=environments/dev/terraform.tfstate -json | jq -r '.database_username.value')
DB_PASS=$(terraform output -state=environments/dev/terraform.tfstate -json | jq -r '.database_password.value')
DB_NAME=$(terraform output -state=environments/dev/terraform.tfstate -raw database_name)

if [ -z "$DB_USER" ] || [ -z "$DB_PASS" ] || [ -z "$DB_NAME" ]; then
    print_error "Could not get database credentials from terraform state"
    exit 1
fi

# Verify SQL files exist
print_status "Verifying SQL files..."
if [ ! -f "$SQL_DIR/init.sql" ] || [ ! -f "$SQL_DIR/add_contacts.sql" ]; then
    print_error "Required SQL files not found in $SQL_DIR"
    exit 1
fi

# Transfer SQL files to EC2
print_status "Transferring SQL files to EC2..."
scp -i $SSH_KEY $SQL_DIR/*.sql $EC2_USER@$EC2_IP:$REMOTE_DIR/
if [ $? -ne 0 ]; then
    print_error "Failed to transfer SQL files to EC2"
    exit 1
fi

# SSH into EC2 and run database initialization
print_status "Initializing database..."
ssh -i $SSH_KEY $EC2_USER@$EC2_IP << EOF
    # Verify MariaDB client is installed
    if ! command -v mysql &> /dev/null; then
        echo "Installing MariaDB client..."
        sudo yum install -y mariadb1011-client-utils
    fi

    # Run init.sql
    echo "Running init.sql..."
    mysql -h ${DB_ENDPOINT%:*} -P ${DB_ENDPOINT#*:} -u $DB_USER -p'$DB_PASS' $DB_NAME < init.sql

    # Run add_contacts.sql
    echo "Running add_contacts.sql..."
    mysql -h ${DB_ENDPOINT%:*} -P ${DB_ENDPOINT#*:} -u $DB_USER -p'$DB_PASS' $DB_NAME < add_contacts.sql

    # Verify data was inserted
    echo "Verifying data insertion..."
    mysql -h ${DB_ENDPOINT%:*} -P ${DB_ENDPOINT#*:} -u $DB_USER -p'$DB_PASS' $DB_NAME -e "SELECT COUNT(*) as total_contacts FROM contacts;"
EOF

if [ $? -ne 0 ]; then
    print_error "Database initialization failed"
    exit 1
fi

print_status "Database initialization completed successfully!"
print_status "You can now test the web application at http://$EC2_IP:8080" 
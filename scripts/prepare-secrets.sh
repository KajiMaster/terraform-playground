#!/bin/bash

# Exit on error
set -e

# Check if environment is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <environment>"
    echo "Example: $0 dev"
    exit 1
fi

ENVIRONMENT=$1
SECRET_NAME="/tf-playground/${ENVIRONMENT}/database/credentials"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "AWS credentials are not configured. Please run 'aws configure' first."
    exit 1
fi

# Generate a strong password that meets AWS RDS requirements
# At least 8 characters, containing uppercase, lowercase, numbers, and special characters
PASSWORD=$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9!@#$%^&*' | head -c 16)
PASSWORD="${PASSWORD}Aa1!"  # Ensure it meets all requirements

# Create the secret value JSON
SECRET_VALUE=$(cat <<EOF
{
    "username": "dbadmin",
    "password": "${PASSWORD}",
    "engine": "mysql",
    "host": "localhost",
    "port": 3306,
    "dbname": "tfplayground"
}
EOF
)

echo "Preparing to update secret: ${SECRET_NAME}"
echo "Secret value will be:"
echo "${SECRET_VALUE}" | jq '.'

# Ask for confirmation
read -p "Do you want to proceed? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 1
fi

# Update the secret
echo "Updating secret..."
aws secretsmanager update-secret \
    --secret-id "${SECRET_NAME}" \
    --secret-string "${SECRET_VALUE}" \
    --description "Database credentials for ${ENVIRONMENT} environment (updated via CLI)"

echo "Secret updated successfully!"
echo "Note: Make sure to save the generated password securely."
echo "Password: ${PASSWORD}"  # Show the password so it can be saved 
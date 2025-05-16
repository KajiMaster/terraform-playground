#!/bin/bash

# Script to securely set up initial database credentials in Parameter Store
# Usage: ./setup-secrets.sh <environment> <username> <password>

set -e

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <environment> <username> <password>"
    echo "Example: $0 dev admin my-secure-password"
    exit 1
fi

ENVIRONMENT=$1
USERNAME=$2
PASSWORD=$3

# Get the KMS key ID from the alias
KMS_KEY_ID=$(aws kms describe-key --key-id "alias/tf-playground-${ENVIRONMENT}-secrets" --query 'KeyMetadata.KeyId' --output text)

if [ -z "$KMS_KEY_ID" ]; then
    echo "Error: KMS key not found. Make sure you've run 'terraform apply' in the bootstrap directory first."
    exit 1
fi

# Set up the parameters
echo "Setting up database credentials in Parameter Store..."

# Username parameter
aws ssm put-parameter \
    --name "/tf-playground/${ENVIRONMENT}/database/username" \
    --value "$USERNAME" \
    --type "SecureString" \
    --key-id "$KMS_KEY_ID" \
    --description "Database master username" \
    --tags "Key=Environment,Value=${ENVIRONMENT}" "Key=Project,Value=tf-playground" "Key=ManagedBy,Value=manual" \
    --overwrite

# Password parameter
aws ssm put-parameter \
    --name "/tf-playground/${ENVIRONMENT}/database/password" \
    --value "$PASSWORD" \
    --type "SecureString" \
    --key-id "$KMS_KEY_ID" \
    --description "Database master password" \
    --tags "Key=Environment,Value=${ENVIRONMENT}" "Key=Project,Value=tf-playground" "Key=ManagedBy,Value=manual" \
    --overwrite

echo "Credentials have been securely stored in Parameter Store."
echo "You can now run 'terraform plan' to verify the configuration." 
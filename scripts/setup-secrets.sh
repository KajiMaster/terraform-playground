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
REGION=${2:-us-east-2}  # Default to us-east-2 if not provided
KMS_ALIAS="alias/tf-playground-${ENVIRONMENT}-secrets"
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

echo "Setting up secrets for environment: ${ENVIRONMENT} in region: ${REGION}"

# Check if KMS key already exists
if aws kms describe-key --key-id "${KMS_ALIAS}" --region "${REGION}" &> /dev/null; then
    echo "KMS key ${KMS_ALIAS} already exists"
else
    echo "Creating KMS key..."
    # Create KMS key
    KMS_KEY_ID=$(aws kms create-key \
        --description "KMS key for tf-playground ${ENVIRONMENT} secrets" \
        --tags TagKey=Environment,TagValue="${ENVIRONMENT}" TagKey=Project,TagValue=tf-playground TagKey=ManagedBy,TagValue=manual \
        --region "${REGION}" \
        --query 'KeyMetadata.KeyId' \
        --output text)

    # Create alias for the key
    aws kms create-alias \
        --alias-name "${KMS_ALIAS}" \
        --target-key-id "${KMS_KEY_ID}" \
        --region "${REGION}"

    echo "Created KMS key with alias: ${KMS_ALIAS}"
fi

# Function to check if secret is in deletion state
check_secret_deletion_state() {
    local secret_id=$1
    local region=$2
    # Use --no-cli-pager to prevent paging issues
    aws secretsmanager describe-secret \
        --secret-id "${secret_id}" \
        --region "${region}" \
        --no-cli-pager \
        --query 'DeletedDate' \
        --output text 2>/dev/null || echo ""
}

# Check if secret exists and handle deletion state
echo "Checking secret status..."
if aws secretsmanager describe-secret --secret-id "${SECRET_NAME}" --region "${REGION}" --no-cli-pager &> /dev/null; then
    SECRET_DELETED_DATE=$(check_secret_deletion_state "${SECRET_NAME}" "${REGION}")
    if [ -n "${SECRET_DELETED_DATE}" ]; then
        echo "Secret ${SECRET_NAME} is in deletion state. Forcing immediate deletion..."
        aws secretsmanager delete-secret \
            --secret-id "${SECRET_NAME}" \
            --force-delete-without-recovery \
            --region "${REGION}" \
            --no-cli-pager
        
        echo "Waiting for secret deletion to complete..."
        while aws secretsmanager describe-secret --secret-id "${SECRET_NAME}" --region "${REGION}" --no-cli-pager &> /dev/null; do
            echo "Still waiting for deletion..."
            sleep 5
        done
        echo "Secret deletion completed"
    fi
else
    echo "Secret ${SECRET_NAME} does not exist"
fi

# Now create or update the secret
if aws secretsmanager describe-secret --secret-id "${SECRET_NAME}" --region "${REGION}" &> /dev/null; then
    echo "Secret ${SECRET_NAME} exists"
    read -p "Do you want to update the secret value? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Secret update skipped"
        exit 0
    fi
else
    echo "Creating secret..."
    # Create the secret (initially with dummy values)
    aws secretsmanager create-secret \
        --name "${SECRET_NAME}" \
        --description "Database credentials for ${ENVIRONMENT} environment" \
        --kms-key-id "${KMS_ALIAS}" \
        --secret-string '{
            "username": "dummy",
            "password": "dummy",
            "engine": "mysql",
            "host": "localhost",
            "port": 3306,
            "dbname": "tfplayground"
        }' \
        --region "${REGION}" \
        --tags Key=Environment,Value="${ENVIRONMENT}" Key=Project,Value=tf-playground Key=ManagedBy,Value=manual Key=Service,Value=database Key=SecretType,Value=credentials

    echo "Created secret: ${SECRET_NAME}"
fi

# Generate a strong password
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

echo "Updating secret with new credentials..."
aws secretsmanager update-secret \
    --secret-id "${SECRET_NAME}" \
    --secret-string "${SECRET_VALUE}" \
    --region "${REGION}"

echo "✅ Setup completed successfully!"
echo "Note: Make sure to save the generated password securely."
echo "Password: ${PASSWORD}"
echo
echo "You can now use these resources in your Terraform configuration:"
echo "KMS Key Alias: ${KMS_ALIAS}"
echo "Secret Name: ${SECRET_NAME}" 
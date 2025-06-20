# Manual State Setup - AWS CLI Commands

## Overview

This document provides individual AWS CLI commands to set up S3 bucket and DynamoDB table for Terraform remote state management.

## Prerequisites

- AWS CLI installed and configured
- Appropriate AWS permissions for S3 and DynamoDB

## Configuration

```bash
# Set variables
BUCKET_NAME="tf-playground-state"
DYNAMODB_TABLE="tf-playground-locks"
REGION="us-east-2"
```

## Step 1: Create S3 Bucket

### Create the bucket

```bash
aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION"
```

### Enable versioning

```bash
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled
```

### Enable server-side encryption

```bash
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'
```

### Block public access

```bash
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

## Step 2: Create DynamoDB Table

### Create the table

```bash
aws dynamodb create-table \
    --table-name "$DYNAMODB_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"
```

### Wait for table to be active

```bash
aws dynamodb wait table-exists \
    --table-name "$DYNAMODB_TABLE" \
    --region "$REGION"
```

### Enable TTL (optional)

```bash
aws dynamodb update-time-to-live \
    --table-name "$DYNAMODB_TABLE" \
    --time-to-live-specification \
        AttributeName=Expires,Enabled=true \
    --region "$REGION"
```

## Step 3: Verify Setup

### Check S3 bucket

```bash
aws s3api head-bucket --bucket "$BUCKET_NAME"
aws s3api get-bucket-versioning --bucket "$BUCKET_NAME"
aws s3api get-bucket-encryption --bucket "$BUCKET_NAME"
```

### Check DynamoDB table

```bash
aws dynamodb describe-table \
    --table-name "$DYNAMODB_TABLE" \
    --region "$REGION"
```

## Step 4: Create Backend Configuration Files

### Dev Environment

```bash
# Create backend.tf for dev environment
cat > environments/dev/backend.tf << 'EOF'
terraform {
  backend "s3" {
    bucket         = "tf-playground-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "tf-playground-locks"
    encrypt        = true
  }
}
EOF
```

### Staging Environment

```bash
# Create backend.tf for staging environment
cat > environments/staging/backend.tf << 'EOF'
terraform {
  backend "s3" {
    bucket         = "tf-playground-state"
    key            = "staging/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "tf-playground-locks"
    encrypt        = true
  }
}
EOF
```

### Production Environment

```bash
# Create backend.tf for production environment
cat > environments/production/backend.tf << 'EOF'
terraform {
  backend "s3" {
    bucket         = "tf-playground-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "tf-playground-locks"
    encrypt        = true
  }
}
EOF
```

## Step 5: Initialize Terraform

### For each environment

```bash
# Dev
cd environments/dev
terraform init

# Staging
cd environments/staging
terraform init

# Production
cd environments/production
terraform init
```

## Troubleshooting

### Check AWS credentials

```bash
aws sts get-caller-identity
```

### Check bucket exists

```bash
aws s3api head-bucket --bucket "$BUCKET_NAME"
```

### Check table exists

```bash
aws dynamodb describe-table \
    --table-name "$DYNAMODB_TABLE" \
    --region "$REGION"
```

### List bucket contents

```bash
aws s3 ls s3://$BUCKET_NAME --recursive
```

## Cost Considerations

### S3 Costs

- Storage: ~$0.023 per GB per month
- Requests: Minimal for state files
- Versioning: Additional storage for history

### DynamoDB Costs

- Read/Write Units: Minimal for locking
- Storage: Minimal for lock entries
- TTL: Automatic cleanup reduces costs

## Security Notes

- Bucket is configured with encryption at rest
- Public access is blocked
- Versioning is enabled for state recovery
- DynamoDB table uses on-demand billing for simplicity

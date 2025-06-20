#!/bin/bash

# Terraform Remote State Setup Script
# This script creates S3 bucket and DynamoDB table for Terraform state management

set -e  # Exit on any error

# Configuration
BUCKET_NAME="tf-playground-state"
DYNAMODB_TABLE="tf-playground-locks"
REGION="us-east-2"

echo "🚀 Setting up Terraform remote state infrastructure..."
echo "Region: $REGION"
echo "S3 Bucket: $BUCKET_NAME"
echo "DynamoDB Table: $DYNAMODB_TABLE"
echo ""

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ AWS CLI configured"

# Check if bucket already exists
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "⚠️  S3 bucket '$BUCKET_NAME' already exists"
else
    echo "📦 Creating S3 bucket: $BUCKET_NAME"
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION"
    
    echo "✅ S3 bucket created successfully"
fi

# Enable versioning on the bucket
echo "🔄 Enabling versioning on S3 bucket"
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

# Enable server-side encryption
echo "🔐 Enabling server-side encryption"
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

# Block public access
echo "🚫 Blocking public access"
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Check if DynamoDB table already exists
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$REGION" >/dev/null 2>&1; then
    echo "⚠️  DynamoDB table '$DYNAMODB_TABLE' already exists"
else
    echo "🗄️  Creating DynamoDB table: $DYNAMODB_TABLE"
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$REGION"
    
    echo "⏳ Waiting for DynamoDB table to be active..."
    aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$REGION"
    echo "✅ DynamoDB table created successfully"
fi

# Enable TTL on DynamoDB table (optional, for automatic cleanup)
echo "⏰ Enabling TTL on DynamoDB table"
aws dynamodb update-time-to-live \
    --table-name "$DYNAMODB_TABLE" \
    --time-to-live-specification \
        AttributeName=Expires,Enabled=true \
    --region "$REGION"

echo ""
echo "🎉 Remote state infrastructure setup complete!"
echo ""
echo "📋 Summary:"
echo "   S3 Bucket: s3://$BUCKET_NAME"
echo "   DynamoDB Table: $DYNAMODB_TABLE"
echo "   Region: $REGION"
echo ""
echo "🔧 Next steps:"
echo "   1. Update backend.tf files in each environment"
echo "   2. Run 'terraform init' in each environment"
echo "   3. Migrate existing state if needed"
echo ""
echo "📚 For more information, see docs/sketch-04-state-management.md" 
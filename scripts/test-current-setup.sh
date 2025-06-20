#!/bin/bash

# Test Current Terraform Setup
# This script helps test the current dev environment configuration

set -e

echo "🔧 Testing Current Terraform Setup"
echo "=================================="
echo ""

# Check if we're in the right directory
if [ ! -f "environments/dev/main.tf" ]; then
    echo "❌ Error: Please run this script from the terraform-playground root directory"
    exit 1
fi

# Set developer name (you can change this)
export TF_VAR_developer="vex"

echo "👤 Developer: $TF_VAR_developer"
echo ""

# Check AWS credentials
echo "🔐 Checking AWS credentials..."
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "❌ Error: AWS credentials not configured"
    echo "Please run: aws configure"
    exit 1
fi
echo "✅ AWS credentials configured"

# Check if key pair exists
echo "🔑 Checking for SSH key pair..."
if ! aws ec2 describe-key-pairs --key-names "tf-playground-key" --region us-east-2 >/dev/null 2>&1; then
    echo "⚠️  SSH key pair 'tf-playground-key' not found"
    echo "Creating new key pair..."
    aws ec2 create-key-pair \
        --key-name "tf-playground-key" \
        --key-type rsa \
        --key-format pem \
        --query 'KeyMaterial' \
        --output text \
        --region us-east-2 > tf-playground-key.pem
    
    chmod 400 tf-playground-key.pem
    echo "✅ Created key pair: tf-playground-key"
    echo "📁 Private key saved as: tf-playground-key.pem"
else
    echo "✅ SSH key pair 'tf-playground-key' exists"
fi

echo ""

# Navigate to dev environment
cd environments/dev

echo "🏗️  Initializing Terraform..."
terraform init

echo ""
echo "📋 Planning Terraform deployment..."
terraform plan -var="key_name=tf-playground-key" -var="developer=$TF_VAR_developer"

echo ""
echo "❓ Do you want to apply this configuration? (y/N)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 Applying Terraform configuration..."
    terraform apply -var="key_name=tf-playground-key" -var="developer=$TF_VAR_developer" -auto-approve
    
    echo ""
    echo "✅ Deployment complete!"
    echo ""
    echo "📊 Outputs:"
    terraform output
    
    echo ""
    echo "🌐 Web server should be available at:"
    echo "   http://$(terraform output -raw webserver_public_ip):8080"
    echo ""
    echo "💾 Database endpoint:"
    echo "   $(terraform output -raw database_endpoint)"
    echo ""
    echo "🔧 To bootstrap the database, run:"
    echo "   aws ssm start-automation-execution --document-name dev-database-automation --region us-east-2"
else
    echo "❌ Deployment cancelled"
fi 
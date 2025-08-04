#!/bin/bash

# Environment switching script for Terraform
# Usage: ./switch-env.sh <environment>
# Example: ./switch-env.sh dev

set -e

ENV=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Validate environment argument
if [ -z "$ENV" ]; then
    echo "Usage: $0 <environment>"
    echo "Available environments: dev, staging, production"
    exit 1
fi

# Validate environment exists
BACKEND_FILE="$SCRIPT_DIR/backend-${ENV}.hcl"
TFVARS_FILE="$SCRIPT_DIR/${ENV}.tfvars"

if [ ! -f "$BACKEND_FILE" ]; then
    echo "Error: Backend configuration not found: $BACKEND_FILE"
    echo "Available environments: dev, staging, production"
    exit 1
fi

if [ ! -f "$TFVARS_FILE" ]; then
    echo "Error: Variables file not found: $TFVARS_FILE"
    echo "Available environments: dev, staging, production"
    exit 1
fi

echo "Switching to environment: $ENV"
echo "Using backend config: $BACKEND_FILE"
echo "Using variables file: $TFVARS_FILE"

# Remove existing .terraform directory to ensure clean init
if [ -d ".terraform" ]; then
    echo "Removing existing .terraform directory..."
    rm -rf .terraform
fi

# Initialize with environment-specific backend
echo "Initializing Terraform with $ENV backend..."
terraform init -backend-config="$BACKEND_FILE"

# Create or select workspace (optional - you may not need workspaces anymore)
echo "Setting up workspace for $ENV..."
terraform workspace select "$ENV" 2>/dev/null || terraform workspace new "$ENV"

echo "Environment switch complete!"
echo ""
echo "You can now run:"
echo "  terraform plan -var-file=$TFVARS_FILE"
echo "  terraform apply -var-file=$TFVARS_FILE"
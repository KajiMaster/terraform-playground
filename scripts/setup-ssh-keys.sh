#!/bin/bash

# Setup SSH Keys for Terraform Playground
# This script creates SSH keys and stores them in AWS Secrets Manager

set -e

# Configuration
ENVIRONMENT="staging"
REGION="us-east-2"
KEY_NAME="staging-managed-key"
SECRET_PREFIX="/tf-playground/${ENVIRONMENT}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔑 Setting up SSH Keys for Terraform Playground${NC}"
echo -e "${BLUE}Environment: ${ENVIRONMENT}${NC}"
echo -e "${BLUE}Region: ${REGION}${NC}"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

# Create SSH key directory if it doesn't exist
SSH_DIR="$HOME/.ssh"
if [ ! -d "$SSH_DIR" ]; then
    echo -e "${YELLOW}📁 Creating SSH directory...${NC}"
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
fi

# Generate SSH key pair if it doesn't exist
PRIVATE_KEY_PATH="$SSH_DIR/${KEY_NAME}"
PUBLIC_KEY_PATH="$SSH_DIR/${KEY_NAME}.pub"

if [ ! -f "$PRIVATE_KEY_PATH" ]; then
    echo -e "${YELLOW}🔐 Generating new SSH key pair...${NC}"
    ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY_PATH" -N "" -C "terraform-playground-${ENVIRONMENT}"
    echo -e "${GREEN}✅ SSH key pair generated${NC}"
else
    echo -e "${YELLOW}⚠️  SSH key pair already exists at $PRIVATE_KEY_PATH${NC}"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f "$PRIVATE_KEY_PATH" "$PUBLIC_KEY_PATH"
        ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY_PATH" -N "" -C "terraform-playground-${ENVIRONMENT}"
        echo -e "${GREEN}✅ SSH key pair regenerated${NC}"
    else
        echo -e "${YELLOW}📝 Using existing SSH key pair${NC}"
    fi
fi

# Set proper permissions
chmod 600 "$PRIVATE_KEY_PATH"
chmod 644 "$PUBLIC_KEY_PATH"

echo ""
echo -e "${BLUE}📤 Storing SSH keys in AWS Secrets Manager...${NC}"

# Store private key in Secrets Manager
PRIVATE_SECRET_NAME="${SECRET_PREFIX}/ssh-key"
echo -e "${YELLOW}🔒 Storing private key...${NC}"

# Check if secret already exists
if aws secretsmanager describe-secret --secret-id "$PRIVATE_SECRET_NAME" --region "$REGION" &> /dev/null; then
    echo -e "${YELLOW}⚠️  Secret $PRIVATE_SECRET_NAME already exists${NC}"
    read -p "Do you want to update it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        aws secretsmanager update-secret \
            --secret-id "$PRIVATE_SECRET_NAME" \
            --secret-string "$(cat "$PRIVATE_KEY_PATH")" \
            --region "$REGION"
        echo -e "${GREEN}✅ Private key updated in Secrets Manager${NC}"
    else
        echo -e "${YELLOW}📝 Using existing private key secret${NC}"
    fi
else
    aws secretsmanager create-secret \
        --name "$PRIVATE_SECRET_NAME" \
        --description "SSH private key for ${ENVIRONMENT} environment" \
        --secret-string "$(cat "$PRIVATE_KEY_PATH")" \
        --region "$REGION"
    echo -e "${GREEN}✅ Private key stored in Secrets Manager${NC}"
fi

# Store public key in Secrets Manager
PUBLIC_SECRET_NAME="${SECRET_PREFIX}/ssh-key-public"
echo -e "${YELLOW}🔓 Storing public key...${NC}"

# Check if secret already exists
if aws secretsmanager describe-secret --secret-id "$PUBLIC_SECRET_NAME" --region "$REGION" &> /dev/null; then
    echo -e "${YELLOW}⚠️  Secret $PUBLIC_SECRET_NAME already exists${NC}"
    read -p "Do you want to update it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        aws secretsmanager update-secret \
            --secret-id "$PUBLIC_SECRET_NAME" \
            --secret-string "$(cat "$PUBLIC_KEY_PATH")" \
            --region "$REGION"
        echo -e "${GREEN}✅ Public key updated in Secrets Manager${NC}"
    else
        echo -e "${YELLOW}📝 Using existing public key secret${NC}"
    fi
else
    aws secretsmanager create-secret \
        --name "$PUBLIC_SECRET_NAME" \
        --description "SSH public key for ${ENVIRONMENT} environment" \
        --secret-string "$(cat "$PUBLIC_KEY_PATH")" \
        --region "$REGION"
    echo -e "${GREEN}✅ Public key stored in Secrets Manager${NC}"
fi

echo ""
echo -e "${GREEN}🎉 SSH Key Setup Complete!${NC}"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo -e "  • Private key: $PRIVATE_KEY_PATH"
echo -e "  • Public key: $PUBLIC_KEY_PATH"
echo -e "  • Private key secret: $PRIVATE_SECRET_NAME"
echo -e "  • Public key secret: $PUBLIC_SECRET_NAME"
echo ""
echo -e "${BLUE}🔧 Next Steps:${NC}"
echo -e "  1. Run 'terraform plan' to see the changes"
echo -e "  2. Run 'terraform apply' to deploy the changes"
echo -e "  3. Use the private key for SSH access:"
echo -e "     ssh -i $PRIVATE_KEY_PATH ubuntu@<instance-ip>"
echo ""
echo -e "${YELLOW}⚠️  Security Notes:${NC}"
echo -e "  • Keep your private key secure and never commit it to version control"
echo -e "  • The private key is now stored encrypted in AWS Secrets Manager"
echo -e "  • Terraform will use the public key from Secrets Manager" 
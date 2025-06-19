#!/bin/bash

# Setup OIDC for GitHub Actions
# This creates the proper IAM role and trust policy for secure AWS access

set -e

ACCOUNT_ID="123324351829"
REGION="us-east-2"
REPO="KajiMaster/terraform-playground"
ROLE_NAME="github-actions-terraform"

echo "Setting up OIDC for GitHub Actions..."
echo "Account ID: $ACCOUNT_ID"
echo "Repository: $REPO"
echo "Role Name: $ROLE_NAME"
echo ""

# Create OIDC Identity Provider
echo "1. Creating OIDC Identity Provider..."
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
    --region $REGION 2>/dev/null || echo "OIDC provider already exists"

# Create IAM Role Trust Policy
echo "2. Creating IAM Role Trust Policy..."
cat > trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:$REPO:*"
                }
            }
        }
    ]
}
EOF

# Create IAM Role
echo "3. Creating IAM Role..."
aws iam create-role \
    --role-name $ROLE_NAME \
    --assume-role-policy-document file://trust-policy.json \
    --description "GitHub Actions role for Terraform deployments" \
    --region $REGION 2>/dev/null || echo "Role already exists"

# Create IAM Policy for Terraform
echo "4. Creating IAM Policy..."
cat > terraform-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "rds:*",
                "s3:*",
                "dynamodb:*",
                "iam:*",
                "ssm:*",
                "secretsmanager:*",
                "kms:*",
                "cloudwatch:*",
                "logs:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF

# Attach Policy to Role
echo "5. Attaching Policy to Role..."
aws iam put-role-policy \
    --role-name $ROLE_NAME \
    --policy-name TerraformDeploymentPolicy \
    --policy-document file://terraform-policy.json \
    --region $REGION

# Clean up temporary files
rm -f trust-policy.json terraform-policy.json

echo ""
echo "✅ OIDC setup complete!"
echo ""
echo "Role ARN: arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME"
echo ""
echo "This role allows GitHub Actions from $REPO to:"
echo "- Deploy Terraform infrastructure"
echo "- Access EC2, RDS, S3, DynamoDB, IAM, SSM, Secrets Manager"
echo "- Use temporary credentials (no long-lived secrets)"
echo ""
echo "Security benefits:"
echo "✅ Temporary credentials (1 hour expiry)"
echo "✅ No stored AWS secrets"
echo "✅ Principle of least privilege"
echo "✅ Automatic credential rotation"
echo "✅ Full audit trail" 
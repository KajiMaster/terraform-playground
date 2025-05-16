# SSH Key Management for Terraform Playground

## Overview

SSH key pairs are managed separately from Terraform infrastructure. This document outlines the process for creating, using, and rotating SSH keys for the project.

## Key Naming Convention

Keys follow the pattern: `tf-playground-${environment}`

- Example: `tf-playground-dev`, `tf-playground-stage`, `tf-playground-prod`

## Initial Key Creation

1. Create the key pair in AWS:

```bash
aws ec2 create-key-pair \
    --key-name tf-playground-dev \
    --query 'KeyMaterial' \
    --output text > ~/.ssh/tf-playground-dev.pem
```

2. Secure the private key:

```bash
chmod 600 ~/.ssh/tf-playground-dev.pem
```

3. Verify the key:

```bash
# Check it's a valid private key
cat ~/.ssh/tf-playground-dev.pem
# Should start with "-----BEGIN RSA PRIVATE KEY-----"
```

## Using the Key

- The private key (`~/.ssh/tf-playground-dev.pem`) stays on your local machine
- Terraform references the key by name (`tf-playground-dev`) in the AWS infrastructure
- To SSH into instances:

```bash
ssh -i ~/.ssh/tf-playground-dev.pem ec2-user@<instance-ip>
```

## Key Rotation

If you need to replace a key pair (e.g., if the private key is lost or compromised):

1. Create a new key pair with a temporary name:

```bash
aws ec2 create-key-pair \
    --key-name tf-playground-dev-new \
    --query 'KeyMaterial' \
    --output text > ~/.ssh/tf-playground-dev-new.pem
chmod 600 ~/.ssh/tf-playground-dev-new.pem
```

2. Update any running instances to use the new key (this can be done through Terraform by updating the key_name)

3. Once all instances are using the new key, delete the old key pair:

```bash
aws ec2 delete-key-pair --key-name tf-playground-dev
```

4. Import the new key with the original name:

```bash
aws ec2 import-key-pair \
    --key-name tf-playground-dev \
    --public-key-material fileb://~/.ssh/tf-playground-dev-new.pub
```

## Important Notes

- Never commit private keys to version control
- Keep private keys secure on your local machine
- Use different key pairs for different environments
- Consider using a key management service for production environments
- The key name in AWS must match what's specified in `terraform.tfvars`

## Troubleshooting

- If you get "Permission denied (publickey)" when trying to SSH:

  - Verify the key name matches in AWS and Terraform
  - Check the key file permissions (should be 600)
  - Ensure you're using the correct username (ec2-user for Amazon Linux)
  - Verify the security group allows SSH access

- If you need to verify a key pair exists in AWS:

```bash
aws ec2 describe-key-pairs --key-name tf-playground-dev
```

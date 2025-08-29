# Secrets Cleanup Migration

**Date**: 2025-08-29  
**Status**: Completed  
**Impact**: Low - No service disruption expected

## Overview

This migration removes deprecated SSH keys and consolidates database password management from AWS Secrets Manager to AWS Systems Manager Parameter Store.

## Background

terraform-playground has evolved from using SSH keys for instance access to using AWS Systems Manager Session Manager. Additionally, database passwords were duplicated between Secrets Manager and Parameter Store. This cleanup removes technical debt and simplifies secrets management.

## Changes Made

### 1. SSH Key Removal

**Removed References:**
- `environments/terraform/main.tf`: Removed SSH key data sources
- `modules/compute/asg/main.tf`: Removed SSH key IAM permissions

**Why SSH Keys Are No Longer Needed:**
- **EC2/ASG**: Uses SSM Session Manager (`aws ssm start-session --target <instance-id>`)
- **ECS Fargate**: Serverless - no instances to SSH into, use ECS Exec
- **EKS**: Use `kubectl exec` for pods, SSM for nodes if needed

### 2. Database Password Consolidation

**Migration Path:**
- FROM: `/tf-playground/all/db-pword` (Secrets Manager)
- TO: `/tf-playground/all/db-password` (Parameter Store)

**Files Updated:**
- `modules/compute/asg/main.tf`: Updated IAM policy from Secrets Manager to Parameter Store
- `modules/compute/asg/templates/user_data.sh`: Updated to use SSM client instead of Secrets Manager
- `app/main.py`: Updated parameter name
- All scripts in `/scripts/` directory
- Bootstrap scripts: `ecs-database-bootstrap.sh`, `eks-database-bootstrap.sh`

### 3. IAM Permission Updates

**Old Permissions (Removed):**
```json
{
  "Action": ["secretsmanager:GetSecretValue"],
  "Resource": [
    "arn:aws:secretsmanager:*:*:secret:/tf-playground/*/db-pword*",
    "arn:aws:secretsmanager:*:*:secret:/tf-playground/all/ssh-key*"
  ]
}
```

**New Permissions (Added):**
```json
{
  "Action": [
    "ssm:GetParameter",
    "ssm:GetParameters",
    "ssm:GetParametersByPath"
  ],
  "Resource": [
    "arn:aws:ssm:*:*:parameter/tf-playground/all/db-password",
    "arn:aws:ssm:*:*:parameter/tf-playground/${environment}/*"
  ]
},
{
  "Action": ["kms:Decrypt"],
  "Resource": "*",
  "Condition": {
    "StringEquals": {
      "kms:ViaService": "ssm.${region}.amazonaws.com"
    }
  }
}
```

**Note on KMS Permissions:** The KMS decrypt permission is required because SSM Parameter Store SecureString parameters are encrypted at rest using AWS KMS. The condition ensures decryption only happens through SSM service calls.

## AWS Resources to Delete

After applying these changes, the following AWS Secrets Manager secrets can be deleted:

```bash
# List secrets that can be deleted
aws secretsmanager list-secrets --region us-east-2 --filters Key=name,Values=/tf-playground

# Delete deprecated secrets (after verification)
aws secretsmanager delete-secret --secret-id /tf-playground/all/db-pword --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id /tf-playground/all/ssh-key --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id /tf-playground/all/ssh-key-public --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id /tf-playground/dev/database/credentials --force-delete-without-recovery
```

## Rollback Plan

If issues occur, the changes can be reverted by:
1. Reverting the git commits
2. Re-applying Terraform
3. Restoring the Secrets Manager secrets from AWS backup (if within recovery window)

## Verification Steps

1. **Test Parameter Store Access:**
```bash
aws ssm get-parameter --name /tf-playground/all/db-password --with-decryption --region us-east-2
```

2. **Test Instance Access (no SSH needed):**
```bash
# Get instance ID
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Environment,Values=staging" --query 'Reservations[0].Instances[0].InstanceId' --output text)

# Connect via Session Manager
aws ssm start-session --target $INSTANCE_ID
```

3. **Verify Application Connectivity:**
```bash
# Test that applications can still connect to database
curl http://your-alb-url/health
```

## Benefits

1. **Simplified Secrets Management**: Single source of truth in Parameter Store
2. **Improved Security**: No SSH keys to manage, rotate, or potentially leak
3. **Cost Reduction**: Fewer Secrets Manager secrets (charged per secret per month)
4. **Better Access Control**: IAM-based access via Session Manager is more auditable
5. **Reduced Attack Surface**: No SSH ports exposed, no key distribution needed

## Lessons Learned

1. **Gradual Migration Works**: Running both systems in parallel allowed safe migration
2. **Parameter Store vs Secrets Manager**: Parameter Store is sufficient for simple key-value secrets
3. **Session Manager Superiority**: SSM Session Manager eliminates SSH key management complexity
4. **Documentation is Critical**: Clear migration docs help future maintainers understand the evolution

## Next Steps

1. Monitor applications for any authentication issues
2. Delete the Secrets Manager secrets after 7-day observation period
3. Consider migrating other secrets to Parameter Store where appropriate
4. Update project documentation to reflect new access patterns

---

*Migration completed by: terraform-playground maintainer*  
*Review status: Pending production validation*
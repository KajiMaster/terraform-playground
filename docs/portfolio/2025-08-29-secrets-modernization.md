---
title: "Modernizing Secrets Management: From SSH Keys to Session Manager"
date: 2025-08-29T12:00:00-03:00
draft: false
tags: ["AWS", "Infrastructure", "Security", "DevOps", "terraform-playground"]
categories: ["Infrastructure Modernization"]
series: ["terraform-playground Evolution"]
toc: true
summary: "How I eliminated SSH key management overhead and consolidated secrets management in terraform-playground, reducing attack surface while improving developer experience."
---

## The Problem I Faced

While auditing terraform-playground's shared services architecture, I discovered technical debt that had accumulated over time:

- **Four deprecated secrets** still existed in AWS Secrets Manager ($0.40/month each)
- **SSH keys** were being fetched but never used (we'd migrated to SSM Session Manager)
- **Duplicate database passwords** in both Secrets Manager and Parameter Store
- **Legacy IAM permissions** granting access to non-existent resources

The code was trying to be "graceful" about missing resources, but it wasn't truly graceful - it would fail during Terraform runs if the secrets didn't exist.

## My Solution Approach

### 1. Investigation Phase

First, I needed to understand what was actually being used versus what was legacy:

```bash
# Found these secrets in AWS but not being used
/tf-playground/all/ssh-key          # Deprecated - using SSM now
/tf-playground/all/ssh-key-public   # Deprecated - using SSM now  
/tf-playground/all/db-pword         # Old parameter name
/tf-playground/dev/database/credentials  # Never actually used
```

### 2. Understanding the "Why"

Before removing anything, I researched why these weren't needed:

- **ECS Fargate**: Serverless containers - no SSH needed, use `aws ecs execute-command`
- **EKS**: Access pods via `kubectl exec`, nodes via SSM if needed
- **EC2/ASG**: Session Manager replaced SSH entirely

This wasn't just cleanup - it was embracing AWS's modern security practices.

### 3. The Migration

I systematically updated each component:

#### Infrastructure Code (Terraform)
```hcl
# BEFORE: Fetching unused SSH keys
data "aws_secretsmanager_secret" "ssh_private" {
  name = local.ssh_private_key_secret_name
}

# AFTER: Clean removal with documentation
# SSH keys removed - not needed for any platform:
# - EC2/ASG: Uses SSM Session Manager (aws ssm start-session)
# - ECS Fargate: Serverless, use ECS Exec (aws ecs execute-command)
# - EKS: Use kubectl exec for pods, SSM for nodes if needed
```

#### IAM Permissions Evolution
```hcl
# BEFORE: Broad Secrets Manager access
{
  Action = ["secretsmanager:GetSecretValue"]
  Resource = ["arn:aws:secretsmanager:*:*:secret:/tf-playground/*"]
}

# AFTER: Specific Parameter Store access with KMS
{
  Action = ["ssm:GetParameter", "ssm:GetParameters"]
  Resource = ["arn:aws:ssm:*:*:parameter/tf-playground/all/db-password"]
},
{
  Action = ["kms:Decrypt"]
  Resource = "*"
  Condition = {
    StringEquals = {
      "kms:ViaService" = "ssm.${region}.amazonaws.com"
    }
  }
}
```

### 4. Script Modernization

Updated all database scripts to use Parameter Store:

```bash
# BEFORE: Using Secrets Manager
DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id "/tf-playground/all/db-pword" \
  --query 'SecretString' --output text)

# AFTER: Using Parameter Store
DB_PASSWORD=$(aws ssm get-parameter \
  --name "/tf-playground/all/db-password" \
  --with-decryption \
  --query 'Parameter.Value' --output text)
```

## Technical Insights Gained

### Why KMS Permissions Matter
Initially, I questioned why we needed KMS permissions for Parameter Store. The answer: SSM Parameter Store SecureString parameters are encrypted at rest using KMS. The condition `"kms:ViaService" = "ssm.amazonaws.com"` ensures decryption only happens through SSM, not direct KMS calls - a crucial security boundary.

### The "Graceful Failure" Misconception
The code claimed to "fail gracefully" when SSH keys were missing, but it actually didn't:
- Terraform data sources without `count` conditions always execute
- Missing secrets cause immediate Terraform failures
- True graceful handling requires conditional resource creation

## Business Impact

### Cost Savings
- Eliminated 4 Secrets Manager secrets: **$1.60/month saved**
- Small win, but it adds up across multiple projects

### Security Improvements
- **Reduced attack surface**: No SSH keys to steal or leak
- **Better audit trail**: Session Manager logs all access
- **No key rotation needed**: IAM handles authentication

### Developer Experience
- **Simpler onboarding**: No SSH key distribution
- **Consistent access**: Same method for all platforms
- **Less configuration**: IAM roles handle everything

## Lessons Learned

1. **Technical debt accumulates silently** - Regular audits reveal hidden cruft
2. **Migration paths matter** - Running parallel systems enabled safe transition
3. **Documentation prevents regression** - Clear comments explain why things were removed
4. **Modern AWS services eliminate complexity** - Session Manager > SSH keys

## What's Next

This cleanup is part of a larger initiative to position terraform-playground as both a learning playground AND a shared services hub. Next steps include:

- Standardizing all projects on Parameter Store
- Implementing automated secret rotation
- Creating a service catalog for common patterns

## Code Samples & References

- [Full Migration PR](#) <!-- Link to GitHub PR -->
- [terraform-playground Repository](https://github.com/KajiMaster/terraform-playground)
- [AWS Session Manager Documentation](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)

---

*This infrastructure modernization reduced complexity while improving security. Sometimes the best code is the code you delete.*
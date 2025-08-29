# Shared Services Architecture

## Overview

terraform-playground serves a **dual purpose**:
1. **Playground Environment**: Experimental infrastructure and learning space
2. **Shared Services Hub**: Central management of shared infrastructure components

This document outlines the shared services managed by terraform-playground that are consumed by other projects.

## Architecture Philosophy

- **Central Management**: Shared resources are defined once and consumed by multiple projects
- **Security Through Centralization**: IAM roles and sensitive parameters managed in one place
- **Cost Efficiency**: Avoid duplicating resources across projects
- **Simplified Maintenance**: Update shared components in one location

## Shared Services Components

### 1. GitHub Actions OIDC Provider & IAM Role

**Resource**: `github-actions-global` IAM Role  
**Location**: `environments/global/main.tf`  
**Module**: `modules/oidc/main.tf`

The global OIDC provider and IAM role enable GitHub Actions workflows across multiple repositories to authenticate with AWS without storing credentials.

**Consuming Projects**:
- virtualexponent-website
- curriculum-designer
- project-glish
- terraform-playground (self)

**Permissions Scope**:
- Terraform state management (S3 + DynamoDB)
- SSM Parameter Store access (`/global/*` and environment-specific)
- EC2, ECS, EKS, Lambda deployment capabilities
- CloudWatch logging and monitoring
- Secrets Manager access

### 2. SSM Parameter Store - Shared Secrets

**Namespace**: `/global/*`  
**Example**: `/global/claude-code/api-key`

Shared parameters that multiple projects need access to are stored under the `/global/` namespace.

**Current Parameters**:
- `/global/claude-code/api-key` - Anthropic API key for Claude Code reviews

**Access Pattern**:
```yaml
# In GitHub Actions workflow
- name: Get Claude API Key
  run: |
    API_KEY=$(aws ssm get-parameter \
      --name /global/claude-code/api-key \
      --with-decryption \
      --query 'Parameter.Value' \
      --output text)
```

### 3. ECR Repository (Global)

**Resource**: `global-tf-pg-ecr`  
**Purpose**: Shared container registry for all environments

While primarily used by terraform-playground, this ECR repository is available for other projects that need container storage in the same AWS account.

### 4. CloudWatch Log Groups

**Location**: `modules/log-groups/`  
**Purpose**: Centralized log management structure

Provides consistent log group naming and retention policies across environments.

### 5. WAF (Web Application Firewall)

**Location**: `modules/waf/`  
**Status**: Available for attachment to any ALB/CloudFront distribution

Shared WAF rules and IP sets that can protect multiple applications.

## Adding New Shared Services

When adding a new shared service:

1. **Determine Scope**: Is this truly shared across projects or project-specific?
2. **Add to Global Environment**: Update `environments/global/main.tf`
3. **Document Here**: Add the service to this document
4. **Update IAM Permissions**: Ensure `github-actions-global` role has necessary permissions
5. **Test Access**: Verify consuming projects can access the resource

## Security Considerations

### Principle of Least Privilege
While `github-actions-global` has broad permissions for convenience, consider:
- Resources are scoped by naming patterns (e.g., `tf-playground-*`)
- SSM parameters are scoped by path (`/global/*`, `/${environment}/*`)
- KMS decryption is limited to SSM service context

### Secrets Management
- All sensitive values use SSM SecureString parameters
- Terraform ignores changes to secret values via lifecycle rules
- Secrets are never committed to git

### Audit Trail
- All shared resources are tagged with:
  - `ManagedBy: terraform`
  - `Project: shared-infrastructure`
  - `Environment: global`
- CloudTrail logs all API calls for audit purposes

## Project Integration Guide

### For New Projects Using Shared Services:

1. **Configure AWS Provider** with us-east-2 region:
```hcl
provider "aws" {
  region = "us-east-2"
}
```

2. **Set up GitHub Actions** with OIDC:
```yaml
permissions:
  id-token: write
  contents: read

steps:
  - name: Configure AWS credentials
    uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::123324351829:role/github-actions-global
      aws-region: us-east-2
```

3. **Access Shared Parameters**:
```bash
aws ssm get-parameter \
  --name /global/parameter-name \
  --with-decryption \
  --region us-east-2
```

## Future Enhancements

### Planned Improvements:
1. **Project-Specific IAM Roles**: Create per-project roles with scoped permissions
2. **Parameter Hierarchy**: Implement `/global/project-name/*` structure
3. **Cross-Account Access**: Support for multi-account architectures
4. **Service Catalog**: Pre-approved infrastructure patterns

### Under Consideration:
- Centralized VPC with shared subnets
- Shared RDS Aurora cluster for development databases
- Global CloudFront distribution with origin failover
- Centralized logging with OpenSearch

## Maintenance

### Regular Tasks:
- Review IAM permissions quarterly
- Rotate shared secrets annually
- Clean up unused parameters monthly
- Audit resource tags for consistency

### Breaking Changes:
When making breaking changes to shared services:
1. Announce in all consuming project channels
2. Provide migration timeline (minimum 2 weeks)
3. Support parallel old/new versions during transition
4. Document migration steps

## Contact

**Primary Maintainer**: terraform-playground repository owner  
**Issues**: Create issue in terraform-playground repository  
**Emergency**: Check CloudWatch alarms and logs first

---

*Last Updated*: 2025-08-29  
*Version*: 1.0.0
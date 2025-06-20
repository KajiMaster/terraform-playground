# Team Development Workflow

## Overview

This document describes how multiple developers can work simultaneously on the Terraform playground without resource conflicts, using individual developer environments.

## The Problem: Shared State File Conflicts

### Scenario: Team of 5 Developers

```
Developer A: feature/database-optimization
Developer B: feature/new-security-groups
Developer C: feature/load-balancer
Developer D: feature/monitoring-setup
Developer E: feature/cache-layer
```

**All using the same dev environment state file** → **Resource conflicts!**

### What Happens Without Individual Environments:

1. **Dev A** creates RDS instance → State file updated
2. **Dev B** tries to create security groups → Conflicts with Dev A's changes
3. **Dev C** modifies VPC → Breaks Dev A and B's resources
4. **State file becomes a bottleneck** → Team productivity plummets

## Solution: Individual Developer Environments

### State File Structure

```
tf-playground-state-vexus/
├── dev-alice/terraform.tfstate     # ✅ Individual - no conflicts
├── dev-bob/terraform.tfstate       # ✅ Individual - no conflicts
├── dev-charlie/terraform.tfstate   # ✅ Individual - no conflicts
├── dev-diana/terraform.tfstate     # ✅ Individual - no conflicts
├── dev-eve/terraform.tfstate       # ✅ Individual - no conflicts
├── staging/terraform.tfstate       # ✅ Shared - integration testing
└── production/terraform.tfstate    # ✅ Shared - production
```

### Resource Isolation

Each developer gets:

- **Unique VPC CIDR**: `192.1.{developer-id}.0/16`
- **Unique Resource Names**: All resources tagged with developer name
- **Separate State File**: No conflicts with other developers
- **Individual Secrets**: Developer-specific database credentials

## Development Lifecycle Management

### The Cost Management Challenge

**Problem**: Multiple dev environments = Cost waste if not managed properly

**Solution**: Structured lifecycle with automated cleanup

### Feature Development Lifecycle

#### Phase 1: Development (Individual Environment)

```bash
# 1. Create feature branch
git checkout -b feature/database-optimization

# 2. Set up individual environment
export TF_VAR_developer=alice
cd environments/dev
terraform apply -auto-approve

# 3. Develop and test
# ... make changes, test infrastructure ...
```

#### Phase 2: Integration (Staging Environment)

```bash
# 4. Create PR to main
git add .
git commit -m "Add database optimization"
git push origin feature/database-optimization

# 5. PR triggers staging deployment
# - GitHub Actions deploys to staging
# - Team reviews changes
# - Integration testing performed
```

#### Phase 3: Cleanup (Destroy Individual Environment)

```bash
# 6. Destroy individual environment (cost savings)
terraform destroy -auto-approve

# 7. Clean up secrets (optional)
aws secretsmanager delete-secret --secret-id /tf-playground/dev-alice/database/credentials --force-delete-without-recovery
```

#### Phase 4: Production (If Approved)

```bash
# 8. Manual approval deploys to production
# - Change request process
# - Stakeholder communication
# - Production deployment
```

### Automated Cleanup Strategies

#### Option 1: Time-Based Cleanup

```bash
# Add to developer setup script
aws events put-rule \
  --name "dev-alice-cleanup" \
  --schedule-expression "rate(24 hours)" \
  --description "Cleanup dev environment after 24 hours"
```

#### Option 2: Branch-Based Cleanup

```bash
# GitHub Actions workflow for cleanup
name: Cleanup Dev Environment
on:
  pull_request:
    types: [closed]
    branches: [main]

jobs:
  cleanup:
    if: github.event.pull_request.merged == true
    runs-on: ubuntu-latest
    steps:
      - name: Destroy Dev Environment
        run: |
          cd environments/dev
          export TF_VAR_developer=${{ github.event.pull_request.user.login }}
          terraform destroy -auto-approve
```

#### Option 3: Manual Cleanup with Reminders

```bash
# Add to team workflow
# - Daily standup: "Who has dev environments running?"
# - Weekly cleanup: "Destroy unused dev environments"
# - Cost alerts: "Dev environment costs > $X"
```

### Cost Optimization Strategies

#### 1. Resource Sizing for Development

```hcl
# environments/dev/variables.tf
variable "webserver_instance_type" {
  default = "t3.micro"  # Smallest instance for dev
}

variable "db_instance_type" {
  default = "db.t3.micro"  # Smallest DB for dev
}

variable "enable_monitoring" {
  default = false  # Disable expensive monitoring in dev
}
```

#### 2. Auto-Stop/Start for Non-Critical Resources

```hcl
# Add to webserver module
resource "aws_ec2_instance_state" "dev_stop" {
  count = var.environment == "dev" ? 1 : 0

  instance_id = aws_instance.webserver.id
  state       = "stopped"

  # Stop instances after 8 PM, start at 8 AM
  lifecycle {
    ignore_changes = [state]
  }
}
```

#### 3. Cost Tracking and Alerts

```bash
# Set up CloudWatch alarms for dev environments
aws cloudwatch put-metric-alarm \
  --alarm-name "dev-alice-cost-alert" \
  --alarm-description "Cost alert for Alice's dev environment" \
  --metric-name "EstimatedCharges" \
  --namespace "AWS/Billing" \
  --statistic "Maximum" \
  --period 86400 \
  --threshold 10 \
  --comparison-operator "GreaterThanThreshold"
```

## Setup Process

### Step 1: Developer Environment Setup

```bash
# Run the setup script with your name
./scripts/setup-developer-env.sh alice

# This creates:
# - KMS alias: alias/tf-playground-dev-alice-secrets
# - Secret: /tf-playground/dev-alice/database/credentials
# - SSH key: tf-playground-dev-alice
```

### Step 2: Initialize Terraform

```bash
cd environments/dev

# Set your developer name
export TF_VAR_developer=alice

# Initialize with your developer-specific state
terraform init
```

### Step 3: Deploy Infrastructure

```bash
# Deploy your individual environment
terraform apply -var='developer=alice' -auto-approve
```

### Step 4: Bootstrap Database

```bash
# Bootstrap your database
aws ssm start-automation-execution \
  --document-name "dev-alice-database-automation" \
  --parameters "DatabaseEndpoint=$(terraform output -raw database_endpoint | sed 's/:3306$//'),DatabaseName=$(terraform output -raw database_name),DatabaseUsername=$(aws secretsmanager get-secret-value --secret-id /tf-playground/dev-alice/database/credentials --region us-east-2 --query SecretString --output text | jq -r '.username'),DatabasePassword=$(aws secretsmanager get-secret-value --secret-id /tf-playground/dev-alice/database/credentials --region us-east-2 --query SecretString --output text | jq -r '.password'),InstanceId=$(terraform output -raw webserver_instance_id),AutomationAssumeRole=$(aws iam get-role --role-name dev-alice-ssm-automation-role --query 'Role.Arn' --output text)" \
  --region us-east-2
```

## Development Workflow

### Feature Development Process

1. **Create Feature Branch**

   ```bash
   git checkout -b feature/my-new-feature
   ```

2. **Set Your Developer Environment**

   ```bash
   export TF_VAR_developer=alice
   cd environments/dev
   ```

3. **Make Changes and Test**

   ```bash
   # Edit Terraform files
   terraform plan
   terraform apply -auto-approve
   ```

4. **Test Your Changes**

   ```bash
   # Test your infrastructure
   curl http://$(terraform output -raw webserver_public_ip):8080
   ```

5. **Commit and Push**

   ```bash
   git add .
   git commit -m "Add new feature"
   git push origin feature/my-new-feature
   ```

6. **Create Pull Request**

   - PR triggers plan on staging environment
   - Team reviews changes
   - Merge to main deploys to staging

7. **Clean Up Dev Environment** ⭐ **IMPORTANT**
   ```bash
   # Destroy your individual environment to save costs
   terraform destroy -auto-approve
   ```

### Team Collaboration

#### Parallel Development

- **Alice**: Working on database optimization
- **Bob**: Working on security groups
- **Charlie**: Working on load balancer
- **No conflicts** - each has their own environment

#### Integration Testing

- **Staging Environment**: Shared for integration testing
- **PR Process**: All changes tested in staging before production
- **Team Review**: Code review and infrastructure validation

## Resource Naming and Tagging

### Automatic Resource Tagging

All resources are automatically tagged with:

```json
{
  "Environment": "dev-alice",
  "Project": "tf-playground",
  "ManagedBy": "terraform",
  "Developer": "alice"
}
```

### Resource Naming Convention

- **VPC**: `dev-alice-vpc`
- **EC2 Instance**: `dev-alice-webserver`
- **RDS Instance**: `dev-alice-database`
- **Security Groups**: `dev-alice-*`

## Cost Management

### Individual Environment Costs

- **Small Resources**: t3.micro instances, minimal storage
- **Auto-Cleanup**: Developers responsible for destroying their environments
- **Cost Tracking**: Resources tagged by developer for cost allocation

### Cleanup Process

```bash
# When done with development
terraform destroy -var='developer=alice' -auto-approve

# Clean up secrets (optional)
aws secretsmanager delete-secret --secret-id /tf-playground/dev-alice/database/credentials --force-delete-without-recovery
```

### Cost Monitoring and Alerts

```bash
# Set up cost alerts for dev environments
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget '{
    "BudgetName": "dev-environments",
    "BudgetLimit": {
      "Amount": "50",
      "Unit": "USD"
    },
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }' \
  --notifications-with-subscribers '[
    {
      "Notification": {
        "ComparisonOperator": "GREATER_THAN",
        "NotificationType": "ACTUAL",
        "Threshold": 80,
        "ThresholdType": "PERCENTAGE"
      },
      "Subscribers": [
        {
          "Address": "team@company.com",
          "SubscriptionType": "EMAIL"
        }
      ]
    }
  ]'
```

## Security Considerations

### Network Isolation

- **Separate VPCs**: Each developer has isolated network
- **Unique CIDR Ranges**: No IP conflicts between developers
- **Individual Security Groups**: Custom rules per developer

### Access Control

- **Developer-Specific Secrets**: Database credentials per developer
- **Individual SSH Keys**: Separate key pairs per developer
- **IAM Roles**: Least privilege access per environment

## Troubleshooting

### Common Issues

1. **State File Not Found**

   ```bash
   # Ensure developer variable is set
   export TF_VAR_developer=alice
   terraform init
   ```

2. **Resource Name Conflicts**

   ```bash
   # Check if resources exist with different developer name
   aws ec2 describe-instances --filters "Name=tag:Project,Values=tf-playground"
   ```

3. **Secret Not Found**
   ```bash
   # Recreate developer environment
   ./scripts/setup-developer-env.sh alice
   ```

### Best Practices

1. **Always Set Developer Variable**

   ```bash
   export TF_VAR_developer=your-name
   ```

2. **Clean Up After Development** ⭐ **CRITICAL**

   ```bash
   terraform destroy -var='developer=your-name' -auto-approve
   ```

3. **Use Descriptive Branch Names**

   ```bash
   git checkout -b feature/database-optimization
   ```

4. **Test in Staging Before Production**

   - All changes go through staging environment
   - Integration testing validates changes
   - Team review ensures quality

5. **Monitor Costs Regularly**
   - Set up cost alerts for dev environments
   - Review costs in team meetings
   - Establish cleanup policies

## Benefits

### ✅ No Resource Conflicts

- Each developer has isolated environment
- No state file contention
- Parallel development possible

### ✅ Cost Effective

- Small resources for development
- Easy cleanup and cost tracking
- Minimal infrastructure overhead

### ✅ Team Productivity

- No blocking between developers
- Rapid iteration and testing
- Clear ownership of resources

### ✅ Enterprise Ready

- Proper resource tagging
- Security isolation
- Audit trail per developer

This workflow ensures your team can work efficiently without the bottlenecks of shared development environments while maintaining cost discipline.

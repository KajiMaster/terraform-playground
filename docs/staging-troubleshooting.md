# Staging Environment Troubleshooting Guide

## Overview
This guide helps troubleshoot issues with the staging environment deployment and validation.

## Common Issues and Solutions

### 1. Validation Script Fails with Exit Code 1

**Symptoms:**
- GitHub Actions validation step fails
- Application not responding correctly
- Invalid JSON responses
- Target groups not healthy

**Root Causes:**
- Infrastructure not fully deployed
- Application not started on instances
- Database connectivity issues
- Invalid AMI ID
- Insufficient wait time for startup

**Solutions:**

#### A. Check Infrastructure Deployment
```bash
# Navigate to staging directory
cd environments/staging

# Check terraform state
terraform state list

# Check if outputs are available
terraform output application_url
```

#### B. Verify AMI ID
The staging environment uses AMI ID: `ami-06c8f2ec674c67112`
- This is the same AMI used in the working dev environment
- If this AMI becomes unavailable, update to a newer Amazon Linux 2023 AMI

#### C. Check Instance Status
```bash
# Get ASG names
BLUE_ASG=$(terraform output -raw blue_asg_name)
GREEN_ASG=$(terraform output -raw green_asg_name)

# Check instance status
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $BLUE_ASG \
  --region us-east-2
```

#### D. Test Application Manually
```bash
# Get ALB URL
ALB_URL=$(terraform output -raw application_url)

# Test health endpoint
curl -v $ALB_URL/health

# Test main application
curl -v $ALB_URL
```

### 2. Application Not Responding

**Symptoms:**
- HTTP 502 Bad Gateway
- Connection timeout
- Invalid JSON responses

**Solutions:**

#### A. Check Target Group Health
```bash
# Get target group ARNs
BLUE_TG=$(terraform output -raw blue_target_group_arn)
GREEN_TG=$(terraform output -raw green_target_group_arn)

# Check health
aws elbv2 describe-target-health \
  --target-group-arn $BLUE_TG \
  --region us-east-2
```

#### B. Check Instance Logs
```bash
# Get instance IDs
INSTANCE_IDS=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $(terraform output -raw blue_asg_name) \
  --region us-east-2 \
  --query 'AutoScalingGroups[0].Instances[?LifecycleState==`InService`].InstanceId' \
  --output text)

# Check system logs
aws logs describe-log-groups --region us-east-2
```

#### C. Verify Security Groups
```bash
# Check ALB security group
ALB_SG=$(terraform output -raw alb_security_group_id)
aws ec2 describe-security-groups \
  --group-ids $ALB_SG \
  --region us-east-2
```

### 3. Database Connectivity Issues

**Symptoms:**
- Application responds but no contacts data
- Database connection errors in logs
- SSM automation failures

**Solutions:**

#### A. Check RDS Status
```bash
# Get database endpoint
DB_ENDPOINT=$(terraform output -raw database_endpoint)

# Check RDS status
aws rds describe-db-instances \
  --region us-east-2 \
  --query 'DBInstances[?Endpoint.Address==`'$DB_ENDPOINT'`]'
```

#### B. Verify SSM Automation
```bash
# Check SSM automation status
SSM_AUTOMATION=$(terraform output -raw ssm_automation_name)
aws ssm describe-automation-executions \
  --region us-east-2 \
  --filters "Key=AutomationType,Values=Local"
```

#### C. Test Database Connection
```bash
# Get database credentials from Secrets Manager
SECRET_ARN=$(terraform output -raw secret_arn)
aws secretsmanager get-secret-value \
  --secret-id $SECRET_ARN \
  --region us-east-2
```

### 4. Blue-Green Configuration Issues

**Symptoms:**
- Only one environment active
- Failover not working
- Target groups misconfigured

**Solutions:**

#### A. Verify ASG Configuration
```bash
# Check both ASGs
BLUE_ASG=$(terraform output -raw blue_asg_name)
GREEN_ASG=$(terraform output -raw green_asg_name)

echo "Blue ASG: $BLUE_ASG"
echo "Green ASG: $GREEN_ASG"

aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $BLUE_ASG $GREEN_ASG \
  --region us-east-2
```

#### B. Check Listener Configuration
```bash
# Get listener ARN
LISTENER_ARN=$(terraform output -raw http_listener_arn)

# Check current target group
aws elbv2 describe-listeners \
  --listener-arns $LISTENER_ARN \
  --region us-east-2
```

### 5. GitHub Actions Workflow Issues

**Symptoms:**
- Workflow not triggering
- Permission errors
- Validation timing out

**Solutions:**

#### A. Check Workflow Triggers
- Ensure workflow file is in `.github/workflows/`
- Verify branch name matches trigger conditions
- Check if workflow file is included in trigger paths

#### B. Verify IAM Permissions
```bash
# Check if OIDC role has required permissions
# Required permissions for staging:
# - ec2:*
# - autoscaling:*
# - elbv2:*
# - rds:*
# - secretsmanager:*
# - ssm:*
# - logs:*
# - iam:PutRolePolicy
# - cloudwatch:*
```

#### C. Increase Wait Times
If validation fails due to timing, increase the wait time in the workflow:
```yaml
# In .github/workflows/staging-terraform.yml
sleep 120  # Increase from 60 to 120 seconds
```

## Debug Scripts

### Simple Test Script
```bash
# Run the simple test script
./scripts/test-staging-simple.sh
```

### Comprehensive Debug Script
```bash
# Run the comprehensive debug script
./scripts/debug-staging.sh
```

### Manual Validation
```bash
# Test the complete blue-green failover
./scripts/blue-green-failover-test.sh staging us-east-2
```

## Prevention Strategies

### 1. Pre-Deployment Checks
- Verify AMI ID is still valid
- Check IAM permissions are sufficient
- Ensure all required modules are up to date

### 2. Monitoring
- Set up CloudWatch alarms for ALB health
- Monitor RDS instance metrics
- Track ASG instance health

### 3. Documentation
- Keep this troubleshooting guide updated
- Document any environment-specific configurations
- Maintain runbooks for common issues

## Emergency Procedures

### 1. Rollback to Previous Version
```bash
# If staging is completely broken, rollback
git checkout <previous-working-commit>
# Re-run the staging workflow
```

### 2. Manual Infrastructure Cleanup
```bash
# If Terraform state is corrupted
cd environments/staging
terraform destroy -auto-approve
# Then re-deploy
```

### 3. Contact Information
- Check GitHub Actions logs for detailed error messages
- Review CloudWatch logs for application errors
- Use AWS Console to inspect resources manually

## Recent Changes Made

1. **Updated AMI ID**: Reverted to same AMI as dev environment
2. **Fixed Green Environment**: Changed from 0 to 1 instance for proper testing
3. **Enhanced Validation**: Added more detailed error reporting and longer wait times
4. **Improved Debugging**: Created comprehensive debug scripts

## Next Steps

1. Commit and push the updated staging configuration
2. Monitor the next staging deployment
3. Run the debug scripts if issues persist
4. Update this guide based on findings 
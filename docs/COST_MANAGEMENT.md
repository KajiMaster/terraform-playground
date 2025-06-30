# Cost Management and Alerting System

This document describes the cost management and alerting system implemented to prevent unexpected AWS charges from lab environments.

## 🚨 Problem Solved

- **Weekend billing surprises**: All 3 environments running over weekends
- **After-hours usage**: Resources running outside business hours
- **No visibility**: No alerts when costs exceed expectations

## 🛡️ Solution Components

### 1. Daily Cleanup Workflow
- **Schedule**: Runs daily at 9 PM UTC (5 PM EST, 2 PM PST)
- **Action**: Destroys all lab environments (dev, staging, production)
- **Safety**: Manual trigger available with confirmation
- **File**: `.github/workflows/destroy-all-labs.yml`

### 2. Cost Monitoring System
- **Daily Budget**: $15 limit with email alerts at 100% and 200%
- **After-Hours Detection**: Lambda function checks for running resources at 8 PM UTC
- **Resource Monitoring**: EC2 instances, RDS databases, Load Balancers
- **Email Alerts**: SNS notifications for cost issues

### 3. AWS Budgets
- **Daily spending limit**: $15 USD
- **Notifications**: Email alerts at 100% and 200% of budget
- **Filtering**: Only tracks resources tagged with `Project = tf-playground`

### 4. After-Hours Monitoring
- **Schedule**: Daily at 8 PM UTC
- **Detection**: Lambda function scans for running resources
- **Alerting**: Email notification with resource list
- **Actions**: Provides instructions to clean up resources

## 📧 Setup Instructions

### 1. Deploy Cost Monitoring System
```bash
# Run the GitHub Actions workflow:
# Actions > Deploy Cost Monitoring System > Run workflow
# Input: DEPLOY-COST-MONITORING
```

### 2. Update Email Address
Edit `environments/global/main.tf`:
```hcl
module "cost_monitoring" {
  source = "../../modules/cost-monitoring"

  environment            = "global"
  daily_budget_limit     = 15.0
  alert_email_addresses  = ["your-actual-email@example.com"]  # ← Update this
  after_hours_check_time = "20:00"
}
```

### 3. Confirm SNS Subscription
- Check your email for SNS subscription confirmation
- Click the confirmation link to activate alerts

### 4. Redeploy Global Environment
```bash
# After updating email, redeploy:
# Actions > Deploy Cost Monitoring System > Run workflow
```

## 🕐 Schedule Overview

| Time (UTC) | Action | Purpose |
|------------|--------|---------|
| 8:00 PM | After-Hours Check | Detect running resources |
| 9:00 PM | Daily Cleanup | Destroy all environments |

## 📊 Alert Examples

### Budget Alert
```
Subject: AWS Budget Alert - tf-playground-daily-lab-budget
Message: You've exceeded 100% of your daily budget ($15.00)
```

### After-Hours Alert
```
Subject: 🚨 Lab Environments Running After Hours
Message: 
🚨 LAB ENVIRONMENTS RUNNING AFTER HOURS 🚨

The following tf-playground resources are still running after business hours:

EC2 Instance: i-1234567890abcdef0
RDS Instance: dev-db
Load Balancer: dev-alb

This may result in unexpected AWS charges.

To stop these resources:
1. Go to GitHub Actions
2. Run the "Daily Lab Cleanup" workflow
3. Or manually destroy environments

Time: 2025-06-26 20:00:00 UTC
```

## 🔧 Customization

### Adjust Daily Budget
Edit `environments/global/main.tf`:
```hcl
daily_budget_limit = 25.0  # Change to $25
```

### Change Alert Times
Edit `environments/global/main.tf`:
```hcl
after_hours_check_time = "19:00"  # 7 PM UTC instead of 8 PM
```

### Modify Cleanup Schedule
Edit `.github/workflows/destroy-all-labs.yml`:
```yaml
schedule:
  - cron: '0 22 * * *'  # 10 PM UTC instead of 9 PM
```

## 🚀 Usage Workflow

### Normal Development Day
1. **Morning**: Deploy dev environment for testing
2. **Afternoon**: Test and iterate
3. **Evening**: 
   - 8 PM: System checks for running resources
   - 9 PM: Automatic cleanup destroys all environments

### Weekend/After Hours
1. **8 PM**: System detects running resources
2. **Email Alert**: You receive notification
3. **Action**: Run manual cleanup or let 9 PM cleanup handle it

### Manual Override
- **Keep environments running**: Disable the daily cleanup workflow
- **Manual cleanup**: Run "Daily Lab Cleanup" workflow manually
- **Individual cleanup**: Use environment-specific destroy workflows

## 💰 Cost Impact

### Before Implementation
- **Weekend costs**: ~$50-100 (all environments running)
- **After-hours costs**: ~$20-40 per night
- **Monthly surprise**: $200-500 unexpected charges

### After Implementation
- **Daily budget**: $15 maximum
- **Automatic cleanup**: $0 after 9 PM
- **Monthly cost**: $0-450 (controlled and predictable)

## 🔍 Monitoring and Troubleshooting

### Check System Status
```bash
# Check Lambda function logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/tf-playground-after-hours-check"

# Check CloudWatch alarms
aws cloudwatch describe-alarms --alarm-names "tf-playground-after-hours-usage"

# Check SNS topic
aws sns list-topics --query 'Topics[?contains(TopicArn, `cost-alerts`)]'
```

### Common Issues
1. **No email alerts**: Check SNS subscription confirmation
2. **False positives**: Verify resource tagging with `Project = tf-playground`
3. **Cleanup failures**: Check GitHub Actions workflow logs
4. **Budget not tracking**: Verify cost filters and tags

## 📝 Best Practices

1. **Always tag resources**: Ensure `Project = tf-playground` tag
2. **Monitor alerts**: Respond to after-hours notifications
3. **Use manual triggers**: When you need environments outside schedule
4. **Review costs**: Check AWS Cost Explorer monthly
5. **Update email**: Keep alert email address current

## 🆘 Emergency Procedures

### Immediate Cost Stop
1. Run "Daily Lab Cleanup" workflow manually
2. Check AWS Console for any remaining resources
3. Manually terminate if needed

### System Disabled
1. Check GitHub Actions workflow status
2. Verify AWS credentials and permissions
3. Check Lambda function logs for errors

### Budget Exceeded
1. Review AWS Cost Explorer for charges
2. Identify which resources are running
3. Manually clean up if automatic cleanup failed 
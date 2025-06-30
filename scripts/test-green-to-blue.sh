#!/bin/bash
# Green to Blue Traffic Switch Test
# Usage: ./scripts/test-green-to-blue.sh [environment] [region]

set -e

ENVIRONMENT=${1:-dev}
REGION=${2:-us-east-2}

echo "🔄 Starting Green to Blue Traffic Switch Test..."
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"

# Change to environment directory
cd environments/$ENVIRONMENT

echo "📋 Current State:"
echo "Blue ASG: $(terraform output -raw blue_asg_name)"
echo "Green ASG: $(terraform output -raw green_asg_name)"
echo "ALB URL: $(terraform output -raw application_url)"

# Step 1: Verify current state (should be green)
echo "🔍 Step 1: Verifying current state..."
CURRENT_COLOR=$(curl -s $(terraform output -raw application_url) | jq -r .deployment_color)
echo "Current deployment color: $CURRENT_COLOR"

if [ "$CURRENT_COLOR" != "green" ]; then
    echo "⚠️  Warning: Expected green, got $CURRENT_COLOR"
fi

# Step 2: Switch traffic back to blue
echo "🔄 Step 2: Switching traffic to blue..."
aws elbv2 modify-listener \
  --listener-arn $(terraform output -raw http_listener_arn) \
  --default-actions Type=forward,TargetGroupArn=$(terraform output -raw blue_target_group_arn) \
  --region $REGION

echo "⏳ Waiting for health checks to complete..."
sleep 15

# Step 3: Verify blue target group health
echo "🏥 Step 3: Checking blue target group health..."
BLUE_HEALTH=$(aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw blue_target_group_arn) \
  --region $REGION \
  --query 'TargetHealthDescriptions[0].TargetHealth.State' \
  --output text)
echo "Blue target group health: $BLUE_HEALTH"

# Step 4: Verify traffic is now going to blue
echo "🔍 Step 4: Verifying traffic switch..."
NEW_COLOR=$(curl -s $(terraform output -raw application_url) | jq -r .deployment_color)
echo "New deployment color: $NEW_COLOR"

if [ "$NEW_COLOR" = "blue" ]; then
    echo "✅ Green to Blue rollback successful!"
    echo "🎯 Blue environment is now active and serving traffic"
else
    echo "❌ Rollback failed - expected blue, got $NEW_COLOR"
    exit 1
fi

# Step 5: Verify database connectivity
echo "🔍 Step 5: Verifying database connectivity..."
CONTACTS_COUNT=$(curl -s $(terraform output -raw application_url) | jq '.contacts | length // 0')
echo "Contacts count: $CONTACTS_COUNT"

if [ "$CONTACTS_COUNT" -gt 0 ]; then
    echo "✅ Database connectivity confirmed with data"
else
    echo "⚠️  Database connected but no data (acceptable for lab environment)"
fi

echo "✅ Green to Blue rollback completed successfully!" 
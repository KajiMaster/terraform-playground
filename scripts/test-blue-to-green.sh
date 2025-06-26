#!/bin/bash
# Blue to Green Traffic Switch Test
# Usage: ./scripts/test-blue-to-green.sh [environment] [region]

set -e

ENVIRONMENT=${1:-dev}
REGION=${2:-us-east-2}

echo "🔄 Starting Blue to Green Traffic Switch Test..."
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"

# Change to environment directory
cd environments/$ENVIRONMENT

echo "📋 Current State:"
echo "Blue ASG: $(terraform output -raw blue_asg_name)"
echo "Green ASG: $(terraform output -raw green_asg_name)"
echo "ALB URL: $(terraform output -raw application_url)"

# Step 1: Verify current state (should be blue)
echo "🔍 Step 1: Verifying current state..."
CURRENT_COLOR=$(curl -s $(terraform output -raw application_url) | jq -r .deployment_color)
echo "Current deployment color: $CURRENT_COLOR"

if [ "$CURRENT_COLOR" != "blue" ]; then
    echo "⚠️  Warning: Expected blue, got $CURRENT_COLOR"
fi

# Step 2: Switch traffic to green
echo "🔄 Step 2: Switching traffic to green..."
aws elbv2 modify-listener \
  --listener-arn $(terraform output -raw http_listener_arn) \
  --default-actions Type=forward,TargetGroupArn=$(terraform output -raw green_target_group_arn) \
  --region $REGION

echo "⏳ Waiting for health checks to complete..."
sleep 15

# Step 3: Verify green target group health
echo "🏥 Step 3: Checking green target group health..."
GREEN_HEALTH=$(aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw green_target_group_arn) \
  --region $REGION \
  --query 'TargetHealthDescriptions[0].TargetHealth.State' \
  --output text)
echo "Green target group health: $GREEN_HEALTH"

# Step 4: Verify traffic is now going to green
echo "🔍 Step 4: Verifying traffic switch..."
NEW_COLOR=$(curl -s $(terraform output -raw application_url) | jq -r .deployment_color)
echo "New deployment color: $NEW_COLOR"

if [ "$NEW_COLOR" = "green" ]; then
    echo "✅ Blue to Green switch successful!"
    echo "🎯 Green environment is now active and serving traffic"
else
    echo "❌ Switch failed - expected green, got $NEW_COLOR"
    exit 1
fi

# Step 5: Verify database connectivity
echo "🔍 Step 5: Verifying database connectivity..."
CONTACTS_COUNT=$(curl -s $(terraform output -raw application_url) | jq '.contacts | length')
echo "Contacts count: $CONTACTS_COUNT"

if [ "$CONTACTS_COUNT" -gt 0 ]; then
    echo "✅ Database connectivity confirmed"
else
    echo "❌ Database connectivity issue"
    exit 1
fi

echo "✅ Blue to Green switch completed successfully!" 
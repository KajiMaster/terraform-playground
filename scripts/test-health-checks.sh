#!/bin/bash
# Health Check Validation Test
# Usage: ./scripts/test-health-checks.sh [environment] [region]

set -e

ENVIRONMENT=${1:-dev}
REGION=${2:-us-east-2}

echo "🏥 Starting Health Check Validation Test..."
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"

# Change to environment directory
cd environments/$ENVIRONMENT

echo "📋 Current State:"
echo "Blue ASG: $(terraform output -raw blue_asg_name)"
echo "Green ASG: $(terraform output -raw green_asg_name)"
echo "ALB URL: $(terraform output -raw application_url)"

# Test 1: ALB Health Check
echo "🔍 Test 1: ALB Health Check..."
ALB_HEALTH=$(curl -s $(terraform output -raw health_check_url))
echo "ALB Health Response: $ALB_HEALTH"

# Extract deployment color
DEPLOYMENT_COLOR=$(echo "$ALB_HEALTH" | jq -r '.deployment_color // "unknown"')
echo "Current deployment color: $DEPLOYMENT_COLOR"

# Test 2: Blue ASG Health
echo "🔍 Test 2: Blue ASG Health..."
BLUE_INSTANCES=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $(terraform output -raw blue_asg_name) \
  --region $REGION \
  --query 'AutoScalingGroups[0].Instances[?LifecycleState==`InService`]' \
  --output text)

if [ -n "$BLUE_INSTANCES" ]; then
    echo "✅ Blue ASG has healthy instances: $BLUE_INSTANCES"
else
    echo "⚠️  Blue ASG has no healthy instances"
fi

# Test 3: Green ASG Health
echo "🔍 Test 3: Green ASG Health..."
GREEN_INSTANCES=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $(terraform output -raw green_asg_name) \
  --region $REGION \
  --query 'AutoScalingGroups[0].Instances[?LifecycleState==`InService`]' \
  --output text)

if [ -n "$GREEN_INSTANCES" ]; then
    echo "✅ Green ASG has healthy instances: $GREEN_INSTANCES"
else
    echo "⚠️  Green ASG has no healthy instances"
fi

# Test 4: Target Group Health
echo "🔍 Test 4: Target Group Health..."

# Blue Target Group Health
BLUE_TG_HEALTH=$(aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw blue_target_group_arn) \
  --region $REGION \
  --query 'TargetHealthDescriptions[?TargetHealth.State==`healthy`]' \
  --output text)

if [ -n "$BLUE_TG_HEALTH" ]; then
    echo "✅ Blue target group has healthy targets"
else
    echo "⚠️  Blue target group has no healthy targets"
fi

# Green Target Group Health
GREEN_TG_HEALTH=$(aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw green_target_group_arn) \
  --region $REGION \
  --query 'TargetHealthDescriptions[?TargetHealth.State==`healthy`]' \
  --output text)

if [ -n "$GREEN_TG_HEALTH" ]; then
    echo "✅ Green target group has healthy targets"
else
    echo "⚠️  Green target group has no healthy targets"
fi

# Test 5: Application Endpoints
echo "🔍 Test 5: Application Endpoints..."

# Health endpoint
HEALTH_RESPONSE=$(curl -s $(terraform output -raw health_check_url))
HEALTH_STATUS=$(echo "$HEALTH_RESPONSE" | jq -r '.status // "unknown"')
echo "Health endpoint status: $HEALTH_STATUS"

# Deployment validation endpoint
VALIDATION_RESPONSE=$(curl -s $(terraform output -raw deployment_validation_url))
VALIDATION_READY=$(echo "$VALIDATION_RESPONSE" | jq -r '.deployment_ready // false')
echo "Deployment validation ready: $VALIDATION_READY"

# Main application endpoint
APP_RESPONSE=$(curl -s $(terraform output -raw application_url))
CONTACTS_COUNT=$(echo "$APP_RESPONSE" | jq -r '.contacts | length // 0')
echo "Application contacts count: $CONTACTS_COUNT"

# Test 6: Performance Check
echo "🔍 Test 6: Performance Check..."
for i in {1..5}; do
    START_TIME=$(date +%s%N)
    curl -s $(terraform output -raw health_check_url) > /dev/null
    END_TIME=$(date +%s%N)
    RESPONSE_TIME=$(( (END_TIME - START_TIME) / 1000000 ))
    echo "Request $i response time: ${RESPONSE_TIME}ms"
done

# Summary
echo ""
echo "📊 Health Check Summary:"
echo "========================="
echo "Current deployment: $DEPLOYMENT_COLOR"
echo "Health status: $HEALTH_STATUS"
echo "Deployment ready: $VALIDATION_READY"
echo "Contacts available: $CONTACTS_COUNT"
echo "Blue ASG instances: $(echo "$BLUE_INSTANCES" | wc -w)"
echo "Green ASG instances: $(echo "$GREEN_INSTANCES" | wc -w)"

if [ "$HEALTH_STATUS" = "healthy" ] && [ "$VALIDATION_READY" = "true" ] && [ "$CONTACTS_COUNT" -gt 0 ]; then
    echo "✅ All health checks passed!"
    exit 0
else
    echo "❌ Some health checks failed!"
    exit 1
fi 
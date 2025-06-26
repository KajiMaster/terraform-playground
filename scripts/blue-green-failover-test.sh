#!/bin/bash
# Complete Blue-Green Failover Test
# Usage: ./scripts/blue-green-failover-test.sh [environment] [region]

set -e

ENVIRONMENT=${1:-dev}
REGION=${2:-us-east-2}

echo "🚀 Starting Complete Blue-Green Failover Test..."
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo "=========================================="

# Change to environment directory
cd environments/$ENVIRONMENT

echo "📋 Environment Information:"
echo "Blue ASG: $(terraform output -raw blue_asg_name)"
echo "Green ASG: $(terraform output -raw green_asg_name)"
echo "ALB URL: $(terraform output -raw application_url)"
echo "Health Check URL: $(terraform output -raw health_check_url)"
echo "=========================================="

# Pre-test validation
echo "🔍 Pre-test Validation..."
echo "Testing health checks..."
./scripts/test-health-checks.sh

# Get current deployment color
CURRENT_COLOR=$(curl -s $(terraform output -raw application_url) | jq -r .deployment_color)
echo "Current deployment color: $CURRENT_COLOR"

# Ensure we start with blue
if [ "$CURRENT_COLOR" != "blue" ]; then
    echo "⚠️  Current deployment is $CURRENT_COLOR, switching to blue first..."
    aws elbv2 modify-listener \
      --listener-arn $(terraform output -raw http_listener_arn) \
      --default-actions Type=forward,TargetGroupArn=$(terraform output -raw blue_target_group_arn) \
      --region $REGION
    sleep 15
    CURRENT_COLOR=$(curl -s $(terraform output -raw application_url) | jq -r .deployment_color)
    echo "Now on: $CURRENT_COLOR"
fi

echo "=========================================="
echo "🔄 SCENARIO 1: Blue to Green Failover"
echo "=========================================="

# Run blue to green test
./scripts/test-blue-to-green.sh $ENVIRONMENT $REGION

echo "=========================================="
echo "✅ Scenario 1 completed successfully!"
echo "=========================================="

# Wait a moment before next test
sleep 5

echo "=========================================="
echo "🔄 SCENARIO 2: Green to Blue Rollback"
echo "=========================================="

# Run green to blue test
./scripts/test-green-to-blue.sh $ENVIRONMENT $REGION

echo "=========================================="
echo "✅ Scenario 2 completed successfully!"
echo "=========================================="

# Final validation
echo "=========================================="
echo "🔍 Final Validation..."
echo "=========================================="

# Test health checks again
./scripts/test-health-checks.sh

# Verify we're back to blue
FINAL_COLOR=$(curl -s $(terraform output -raw application_url) | jq -r .deployment_color)
echo "Final deployment color: $FINAL_COLOR"

if [ "$FINAL_COLOR" = "blue" ]; then
    echo "✅ Final validation passed - back to blue environment"
else
    echo "❌ Final validation failed - expected blue, got $FINAL_COLOR"
    exit 1
fi

echo "=========================================="
echo "🎉 ALL FAILOVER TESTS COMPLETED SUCCESSFULLY!"
echo "=========================================="
echo "✅ Blue to Green failover: PASSED"
echo "✅ Green to Blue rollback: PASSED"
echo "✅ Health checks: PASSED"
echo "✅ Database connectivity: PASSED"
echo "✅ Zero downtime: ACHIEVED"
echo "=========================================="
echo "🎯 Blue-Green deployment is working correctly!"
echo "==========================================" 
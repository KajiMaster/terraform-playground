#!/bin/bash
# Debug script for staging environment
# Usage: ./scripts/debug-staging.sh

set -e

echo "🔍 Debugging Staging Environment..."
echo "=========================================="

# Change to staging directory
cd environments/staging

echo "📋 Terraform State Check:"
echo "========================="

# Check if terraform is initialized
if [ -d ".terraform" ]; then
    echo "✅ Terraform is initialized"
else
    echo "❌ Terraform is not initialized"
    exit 1
fi

# Check terraform state
echo ""
echo "📊 Terraform State:"
terraform state list | head -20

echo ""
echo "🌐 Infrastructure Outputs:"
echo "=========================="

# Try to get outputs
if terraform output application_url >/dev/null 2>&1; then
    ALB_URL=$(terraform output -raw application_url)
    echo "✅ ALB URL: $ALB_URL"
    
    # Test ALB connectivity
    echo ""
    echo "🔍 Testing ALB Connectivity:"
    echo "============================"
    
    # Test with curl
    echo "Testing ALB URL..."
    if curl -s -o /dev/null -w "%{http_code}" "$ALB_URL" | grep -q "200\|301\|302"; then
        echo "✅ ALB is responding"
        
        # Get actual response
        RESPONSE=$(curl -s "$ALB_URL")
        echo "Response preview: ${RESPONSE:0:200}..."
        
        # Check if it's JSON
        if echo "$RESPONSE" | jq . >/dev/null 2>&1; then
            echo "✅ Response is valid JSON"
            DEPLOYMENT_COLOR=$(echo "$RESPONSE" | jq -r '.deployment_color // "unknown"')
            CONTACTS_COUNT=$(echo "$RESPONSE" | jq '.contacts | length // 0')
            echo "Deployment Color: $DEPLOYMENT_COLOR"
            echo "Contacts Count: $CONTACTS_COUNT"
        else
            echo "❌ Response is not valid JSON"
            echo "Full response: $RESPONSE"
        fi
    else
        echo "❌ ALB is not responding correctly"
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$ALB_URL")
        echo "HTTP Status Code: $HTTP_CODE"
    fi
else
    echo "❌ Cannot get ALB URL from terraform outputs"
fi

echo ""
echo "🎯 Target Group Check:"
echo "======================"

# Check target groups
if terraform output blue_target_group_arn >/dev/null 2>&1; then
    BLUE_TG_ARN=$(terraform output -raw blue_target_group_arn)
    echo "Blue Target Group ARN: $BLUE_TG_ARN"
    
    # Check target health
    BLUE_HEALTH=$(aws elbv2 describe-target-health \
      --target-group-arn "$BLUE_TG_ARN" \
      --region us-east-2 \
      --query 'TargetHealthDescriptions[0].TargetHealth.State' \
      --output text 2>/dev/null || echo "unknown")
    
    echo "Blue Target Health: $BLUE_HEALTH"
else
    echo "❌ Cannot get blue target group ARN"
fi

if terraform output green_target_group_arn >/dev/null 2>&1; then
    GREEN_TG_ARN=$(terraform output -raw green_target_group_arn)
    echo "Green Target Group ARN: $GREEN_TG_ARN"
    
    # Check target health
    GREEN_HEALTH=$(aws elbv2 describe-target-health \
      --target-group-arn "$GREEN_TG_ARN" \
      --region us-east-2 \
      --query 'TargetHealthDescriptions[0].TargetHealth.State' \
      --output text 2>/dev/null || echo "unknown")
    
    echo "Green Target Health: $GREEN_HEALTH"
else
    echo "❌ Cannot get green target group ARN"
fi

echo ""
echo "🚀 Auto Scaling Groups:"
echo "======================="

# Check ASGs
if terraform output blue_asg_name >/dev/null 2>&1; then
    BLUE_ASG_NAME=$(terraform output -raw blue_asg_name)
    echo "Blue ASG Name: $BLUE_ASG_NAME"
    
    # Get ASG details
    BLUE_ASG_INFO=$(aws autoscaling describe-auto-scaling-groups \
      --auto-scaling-group-names "$BLUE_ASG_NAME" \
      --region us-east-2 \
      --query 'AutoScalingGroups[0].{DesiredCapacity:DesiredCapacity,MinSize:MinSize,MaxSize:MaxSize,Instances:length(Instances)}' \
      --output json 2>/dev/null || echo '{}')
    
    echo "Blue ASG Info: $BLUE_ASG_INFO"
else
    echo "❌ Cannot get blue ASG name"
fi

if terraform output green_asg_name >/dev/null 2>&1; then
    GREEN_ASG_NAME=$(terraform output -raw green_asg_name)
    echo "Green ASG Name: $GREEN_ASG_NAME"
    
    # Get ASG details
    GREEN_ASG_INFO=$(aws autoscaling describe-auto-scaling-groups \
      --auto-scaling-group-names "$GREEN_ASG_NAME" \
      --region us-east-2 \
      --query 'AutoScalingGroups[0].{DesiredCapacity:DesiredCapacity,MinSize:MinSize,MaxSize:MaxSize,Instances:length(Instances)}' \
      --output json 2>/dev/null || echo '{}')
    
    echo "Green ASG Info: $GREEN_ASG_INFO"
else
    echo "❌ Cannot get green ASG name"
fi

echo ""
echo "📊 Summary:"
echo "==========="
echo "This debug script will help identify what's causing the staging validation to fail."
echo "Check the output above for any ❌ errors or unexpected values." 
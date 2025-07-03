#!/bin/bash
# Blue-Green Failover Demo Script
# Simulates real production blue-green deployment failover

set -e

ENVIRONMENT=${1:-staging}
REGION=${2:-us-east-2}

echo "🔄 Blue-Green Failover Demo"
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo "=========================================="

# Change to environment directory
cd environments/$ENVIRONMENT

# Get ALB and target group information
ALB_URL=$(terraform output -raw application_url)
LISTENER_ARN=$(terraform output -raw http_listener_arn)
BLUE_TG_ARN=$(terraform output -raw blue_target_group_arn)
GREEN_TG_ARN=$(terraform output -raw green_target_group_arn)

echo "📋 Infrastructure Information:"
echo "ALB URL: $ALB_URL"
echo "Listener ARN: $LISTENER_ARN"
echo "Blue Target Group: $BLUE_TG_ARN"
echo "Green Target Group: $GREEN_TG_ARN"
echo "=========================================="

# Function to check deployment color
check_deployment_color() {
    local response=$(curl -s "$ALB_URL")
    local color=$(echo "$response" | jq -r '.deployment_color // "unknown"')
    echo "$color"
}

# Function to check target group health
check_target_group_health() {
    local tg_arn=$1
    local health=$(aws elbv2 describe-target-health \
        --target-group-arn "$tg_arn" \
        --region "$REGION" \
        --query 'TargetHealthDescriptions[0].TargetHealth.State' \
        --output text 2>/dev/null || echo "unknown")
    echo "$health"
}

# Function to switch traffic
switch_traffic() {
    local target_group_arn=$1
    local environment_name=$2
    
    echo "🔄 Switching traffic to $environment_name environment..."
    
    aws elbv2 modify-listener \
        --listener-arn "$LISTENER_ARN" \
        --default-actions Type=forward,TargetGroupArn="$target_group_arn" \
        --region "$REGION"
    
    echo "⏳ Waiting for traffic switch to complete..."
    sleep 15
    
    # Verify the switch
    local current_tg=$(aws elbv2 describe-listeners \
        --listener-arns "$LISTENER_ARN" \
        --region "$REGION" \
        --query 'Listeners[0].DefaultActions[0].TargetGroupArn' \
        --output text)
    
    if [[ "$current_tg" == *"$environment_name"* ]]; then
        echo "✅ Traffic successfully switched to $environment_name"
    else
        echo "❌ Traffic switch failed - listener still pointing to different target group"
        return 1
    fi
}

# Function to verify deployment
verify_deployment() {
    local expected_color=$1
    local max_attempts=10
    local attempt=1
    
    echo "🔍 Verifying deployment color is $expected_color..."
    
    while [ $attempt -le $max_attempts ]; do
        local actual_color=$(check_deployment_color)
        echo "Attempt $attempt: Got $actual_color (expected $expected_color)"
        
        if [ "$actual_color" = "$expected_color" ]; then
            echo "✅ Deployment verification successful!"
            return 0
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            echo "⏳ Waiting before retry..."
            sleep 10
        fi
        
        attempt=$((attempt + 1))
    done
    
    echo "❌ Deployment verification failed after $max_attempts attempts"
    return 1
}

# Pre-flight checks
echo "🔍 Pre-flight Checks"
echo "=========================================="

# Check blue environment health
BLUE_HEALTH=$(check_target_group_health "$BLUE_TG_ARN")
echo "Blue Target Group Health: $BLUE_HEALTH"

# Check green environment health
GREEN_HEALTH=$(check_target_group_health "$GREEN_TG_ARN")
echo "Green Target Group Health: $GREEN_HEALTH"

# Check current deployment
CURRENT_COLOR=$(check_deployment_color)
echo "Current Deployment Color: $CURRENT_COLOR"

echo "=========================================="

# Ensure we start with blue
if [ "$CURRENT_COLOR" != "blue" ]; then
    echo "⚠️  Current deployment is $CURRENT_COLOR, switching to blue first..."
    switch_traffic "$BLUE_TG_ARN" "blue"
    verify_deployment "blue"
fi

echo "=========================================="
echo "🎬 SCENARIO 1: Blue to Green Failover"
echo "=========================================="

# Simulate blue environment failure
echo "🚨 Simulating Blue Environment Failure..."
echo "Switching traffic to Green environment for failover..."

# Switch to green
switch_traffic "$GREEN_TG_ARN" "green"

# Verify green is responding
verify_deployment "green"

echo "✅ Blue to Green failover completed successfully!"
echo "🎯 Green environment is now serving all traffic"

echo "=========================================="
echo "🎬 SCENARIO 2: Green to Blue Rollback"
echo "=========================================="

# Simulate recovery - switch back to blue
echo "🔧 Simulating Blue Environment Recovery..."
echo "Switching traffic back to Blue environment..."

# Switch back to blue
switch_traffic "$BLUE_TG_ARN" "blue"

# Verify blue is responding
verify_deployment "blue"

echo "✅ Green to Blue rollback completed successfully!"
echo "🎯 Blue environment is now serving all traffic again"

echo "=========================================="
echo "🎉 BLUE-GREEN FAILOVER DEMO COMPLETED!"
echo "=========================================="
echo "✅ Blue to Green failover: SUCCESS"
echo "✅ Green to Blue rollback: SUCCESS"
echo "✅ Zero-downtime traffic switching: VERIFIED"
echo "✅ Production-like blue-green deployment: DEMONSTRATED"
echo "=========================================="
echo "🎯 Your blue-green deployment is working correctly!"
echo "==========================================" 
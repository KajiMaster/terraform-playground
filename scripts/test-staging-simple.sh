#!/bin/bash
# Simple staging environment test
# Usage: ./scripts/test-staging-simple.sh

set -e

echo "🔍 Simple Staging Environment Test"
echo "=================================="

# Change to staging directory
cd environments/staging

echo "📋 Checking Terraform State..."
if [ -d ".terraform" ]; then
    echo "✅ Terraform initialized"
else
    echo "❌ Terraform not initialized"
    exit 1
fi

echo ""
echo "🌐 Testing Application URLs..."

# Get URLs
if terraform output application_url >/dev/null 2>&1; then
    ALB_URL=$(terraform output -raw application_url)
    HEALTH_URL=$(terraform output -raw health_check_url)
    
    echo "ALB URL: $ALB_URL"
    echo "Health URL: $HEALTH_URL"
    
    echo ""
    echo "🔍 Testing Health Endpoint..."
    if curl -s -f "$HEALTH_URL" >/dev/null 2>&1; then
        echo "✅ Health endpoint is responding"
        HEALTH_RESPONSE=$(curl -s "$HEALTH_URL")
        echo "Health response: $HEALTH_RESPONSE"
    else
        echo "❌ Health endpoint not responding"
    fi
    
    echo ""
    echo "🌐 Testing Main Application..."
    if curl -s -f "$ALB_URL" >/dev/null 2>&1; then
        echo "✅ Main application is responding"
        APP_RESPONSE=$(curl -s "$ALB_URL")
        echo "App response preview: ${APP_RESPONSE:0:200}..."
        
        # Try to parse JSON
        if echo "$APP_RESPONSE" | jq . >/dev/null 2>&1; then
            echo "✅ Response is valid JSON"
            DEPLOYMENT_COLOR=$(echo "$APP_RESPONSE" | jq -r '.deployment_color // "unknown"')
            CONTACTS_COUNT=$(echo "$APP_RESPONSE" | jq '.contacts | length // 0')
            echo "Deployment Color: $DEPLOYMENT_COLOR"
            echo "Contacts Count: $CONTACTS_COUNT"
        else
            echo "❌ Response is not valid JSON"
            echo "Full response: $APP_RESPONSE"
        fi
    else
        echo "❌ Main application not responding"
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$ALB_URL")
        echo "HTTP Status Code: $HTTP_CODE"
    fi
else
    echo "❌ Cannot get application URLs from terraform outputs"
    echo "This might mean the infrastructure is not deployed yet"
fi

echo ""
echo "📊 Summary:"
echo "==========="
echo "If you see ❌ errors above, the staging environment needs attention."
echo "Common issues:"
echo "- Infrastructure not deployed"
echo "- Application not started"
echo "- Database connectivity issues"
echo "- Invalid AMI ID"
echo ""
echo "To fix:"
echo "1. Check if the staging workflow ran successfully"
echo "2. Verify the AMI ID is still valid"
echo "3. Check if instances are running and healthy"
echo "4. Review application logs for startup issues" 
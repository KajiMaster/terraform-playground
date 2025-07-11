#!/bin/bash

set -e

echo "🎬 Starting Logging Infrastructure Demo..."

# Get environment variables
ENVIRONMENT=${1:-staging}
REGION=${2:-us-east-2}

cd environments/$ENVIRONMENT

echo "📊 Step 1: Normal Operation Dashboard"
echo "Dashboard URL: $(terraform output -raw dashboard_url)"
echo "Press Enter to continue..."

# 2. Run chaos testing
echo "🎭 Step 2: Generating Failures..."
cd ../..
./scripts/chaos-testing.sh

# 3. Show real-time alerts
echo "🚨 Step 3: Real-time Alerts"
echo "Check your email/Slack for alerts!"
echo "Press Enter to continue..."

# 4. Show log analysis
echo "📋 Step 4: Log Analysis"
echo "CloudWatch Logs: https://console.aws.amazon.com/cloudwatch/home?region=$REGION#logsV2:log-groups/log-group/%2Faws%2Fapplication%2F$ENVIRONMENT"

# 5. Show troubleshooting
echo "🔧 Step 5: Troubleshooting with Logs"
echo "Recent errors:"
aws logs filter-log-events \
  --log-group-name "/aws/application/$ENVIRONMENT" \
  --filter-pattern "ERROR" \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --region $REGION

echo "✅ Demo completed!"
echo "📊 Dashboard: $(terraform output -raw dashboard_url)" 
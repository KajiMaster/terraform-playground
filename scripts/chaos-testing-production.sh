#!/bin/bash

set -e

echo "🎭 Starting Production Chaos Testing..."

# CRITICAL: Force production environment only
# Get the script directory and find the production environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRODUCTION_DIR="$SCRIPT_DIR/../environments/production"

# Verify we're working with production environment
if [ ! -d "$PRODUCTION_DIR" ]; then
    echo "❌ Error: Production environment directory not found: $PRODUCTION_DIR"
    echo "   Script location: $SCRIPT_DIR"
    exit 1
fi

# Force change to production directory - NO OTHER ENVIRONMENT ALLOWED
cd "$PRODUCTION_DIR"

# Verify this is actually the production environment
if [ ! -f "main.tf" ]; then
    echo "❌ Error: main.tf not found in production environment"
    echo "   Current directory: $(pwd)"
    exit 1
fi

# Check for production indicators in main.tf
if ! grep -q "Tier.*production" main.tf 2>/dev/null && ! grep -q "production" main.tf 2>/dev/null; then
    echo "❌ Error: This does not appear to be the production environment"
    echo "   Expected: environments/production with production configuration"
    echo "   Current directory: $(pwd)"
    echo "   Checking for 'Tier = \"production\"' or 'production' in main.tf"
    exit 1
fi

echo "✅ Confirmed: Working in PRODUCTION environment only"

# Configuration
echo "🔍 Getting production application URL..."
if ! BASE_URL=$(terraform output -raw application_url 2>/dev/null); then
    echo "❌ Error: Could not get application_url from Terraform outputs"
    echo "   Make sure you're in the production environment directory and it has been applied"
    echo "   Available outputs:"
    terraform output
    exit 1
fi
REGION="us-east-2"

echo "📋 Production Base URL: $BASE_URL"
echo "⚠️  WARNING: This is PRODUCTION environment!"
echo "   Proceeding with reduced intensity for safety..."

# Test 1: Generate 500 Errors (reduced count for production)
echo "🔥 Generating 500 errors (production-safe)..."
for i in {1..5}; do
    echo "  Request $i: $(curl -s -w "HTTP %{http_code}" "$BASE_URL/error/500" -o /dev/null)"
    sleep 1.0  # Slower pace for production
done

# Test 2: Generate Slow Responses (reduced count for production)
echo "🐌 Generating slow responses (production-safe)..."
for i in {1..5}; do
    echo "  Slow request $i: $(curl -s -w "HTTP %{http_code} Time: %{time_total}s" "$BASE_URL/error/slow" -o /dev/null --max-time 10)"
    sleep 1.0  # Slower pace for production
done

# Test 2b: Generate Very Slow Responses (should trigger alarm) - reduced for production
echo "🐌🐌 Generating very slow responses (production-safe)..."
for i in {1..3}; do
    echo "  Very slow request $i: $(curl -s -w "HTTP %{http_code} Time: %{time_total}s" "$BASE_URL/error/slow" -o /dev/null --max-time 15)"
    sleep 0.5  # Slower pace for production
done

# Test 3: Generate Database Errors (reduced count for production)
echo "💾 Generating database errors (production-safe)..."
for i in {1..3}; do
    echo "  DB error $i: $(curl -s -w "HTTP %{http_code}" "$BASE_URL/error/db" -o /dev/null)"
    sleep 1.0  # Slower pace for production
done

# Test 4: High Load Test (reduced intensity for production)
echo "📈 Generating moderate load (production-safe)..."
for i in {1..10}; do
    curl -s "$BASE_URL/health" > /dev/null &
    curl -s "$BASE_URL/" > /dev/null &
    if [ $((i % 3)) -eq 0 ]; then
        echo "  Load test progress: $i/10 requests"
    fi
    sleep 0.3  # Slower pace for production
done

# Test 5: WAF Rate Limiting Test (production-specific)
echo "🛡️ Testing WAF rate limiting..."
echo "  Sending rapid requests to test WAF protection..."
for i in {1..15}; do
    echo "  WAF test $i: $(curl -s -w "HTTP %{http_code}" "$BASE_URL/health" -o /dev/null)"
    sleep 0.1  # Rapid requests to trigger rate limiting
done

echo "✅ Production chaos testing completed!"
echo "📊 Check CloudWatch dashboard for results:"
echo "https://console.aws.amazon.com/cloudwatch/home?region=$REGION#dashboards:name=tf-playground-production"
echo ""
echo "🛡️ Check WAF logs for rate limiting activity:"
echo "https://console.aws.amazon.com/wafv2/home?region=$REGION#/web-acls"
echo ""
echo "🔒 Production environment isolation verified:"
echo "   - Working directory: $(pwd)"
echo "   - Target URL: $BASE_URL"
echo "   - Environment: PRODUCTION ONLY" 
#!/bin/bash

set -e

echo "🎭 Starting Chaos Testing..."

# Change to staging directory first
cd environments/staging

# Configuration
BASE_URL=$(terraform output -raw application_url)
REGION="us-east-2"

echo "📋 Base URL: $BASE_URL"

# Test 1: Generate 500 Errors
echo "🔥 Generating 500 errors..."
for i in {1..10}; do
    echo "  Request $i: $(curl -s -w "HTTP %{http_code}" "$BASE_URL/error/500" -o /dev/null)"
    sleep 0.5
done

# Test 2: Generate Slow Responses
echo "🐌 Generating slow responses..."
for i in {1..10}; do
    echo "  Slow request $i: $(curl -s -w "HTTP %{http_code} Time: %{time_total}s" "$BASE_URL/error/slow" -o /dev/null --max-time 10)"
    sleep 0.5
done

# Test 2b: Generate Very Slow Responses (should trigger alarm)
echo "🐌🐌 Generating very slow responses..."
for i in {1..5}; do
    echo "  Very slow request $i: $(curl -s -w "HTTP %{http_code} Time: %{time_total}s" "$BASE_URL/error/slow" -o /dev/null --max-time 15)"
    sleep 0.3
done

# Test 3: Generate Database Errors
echo "💾 Generating database errors..."
for i in {1..5}; do
    echo "  DB error $i: $(curl -s -w "HTTP %{http_code}" "$BASE_URL/error/db" -o /dev/null)"
    sleep 0.5
done

# Test 4: High Load Test
echo "📈 Generating high load..."
for i in {1..20}; do
    curl -s "$BASE_URL/health" > /dev/null &
    curl -s "$BASE_URL/" > /dev/null &
    if [ $((i % 5)) -eq 0 ]; then
        echo "  Load test progress: $i/20 requests"
    fi
    sleep 0.1
done

echo "✅ Chaos testing completed!"
echo "📊 Check CloudWatch dashboard for results:"
echo "https://console.aws.amazon.com/cloudwatch/home?region=$REGION#dashboards:name=tf-playground-staging" 
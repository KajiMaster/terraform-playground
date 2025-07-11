#!/bin/bash

set -e

echo "🎭 Starting Chaos Testing..."

# Configuration
BASE_URL=$(terraform output -raw application_url)
REGION="us-east-2"

echo "📋 Base URL: $BASE_URL"

# Test 1: Generate 500 Errors
echo "🔥 Generating 500 errors..."
for i in {1..10}; do
    curl -s "$BASE_URL/error/500" &
    sleep 0.5
done

# Test 2: Generate Slow Responses
echo "🐌 Generating slow responses..."
for i in {1..5}; do
    curl -s "$BASE_URL/error/slow" &
    sleep 1
done

# Test 3: Generate Database Errors
echo "💾 Generating database errors..."
for i in {1..5}; do
    curl -s "$BASE_URL/error/db" &
    sleep 0.5
done

# Test 4: High Load Test
echo "📈 Generating high load..."
for i in {1..20}; do
    curl -s "$BASE_URL/health" &
    curl -s "$BASE_URL/" &
    sleep 0.1
done

echo "✅ Chaos testing completed!"
echo "📊 Check CloudWatch dashboard for results:"
echo "https://console.aws.amazon.com/cloudwatch/home?region=$REGION#dashboards:name=tf-playground-staging" 
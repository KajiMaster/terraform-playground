#!/bin/bash

set -e

echo "🔐 Testing Parameter Store Integration"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if AWS credentials are available
echo "🔍 Checking AWS credentials..."
if aws sts get-caller-identity >/dev/null 2>&1; then
    print_status "AWS credentials found"
    AWS_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
    echo "  AWS Account: $AWS_ACCOUNT"
else
    print_error "AWS credentials not found. Please configure AWS CLI first."
    exit 1
fi

# Check if Parameter Store parameter exists
echo ""
echo "🔍 Checking Parameter Store parameter..."
if aws ssm get-parameter --name "/tf-playground/all/db-pword" --with-decryption --region us-east-2 >/dev/null 2>&1; then
    print_status "Parameter Store parameter exists"
    PARAM_VALUE=$(aws ssm get-parameter --name "/tf-playground/all/db-pword" --with-decryption --region us-east-2 --query 'Parameter.Value' --output text)
    echo "  Parameter value: ${PARAM_VALUE:0:10}..."
else
    print_error "Parameter Store parameter not found"
    exit 1
fi

# Clean up any existing test container
echo ""
echo "🧹 Cleaning up existing test container..."
sudo docker stop test-parameter-store 2>/dev/null || true
sudo docker rm test-parameter-store 2>/dev/null || true

# Start container with AWS credentials
echo ""
echo "🚀 Starting container with AWS credentials..."
sudo docker run -d \
  --name test-parameter-store \
  -p 8081:8080 \
  -v ~/.aws:/home/app/.aws:ro \
  -e AWS_PROFILE=default \
  -e DB_HOST=localhost \
  -e DB_USER=test \
  -e DB_NAME=test \
  -e DEPLOYMENT_COLOR=parameter-store-test \
  app-flask-app

# Wait for container to start
echo "⏳ Waiting for container to start..."
sleep 10

# Test the application
echo ""
echo "🧪 Testing application with Parameter Store..."

# Test health endpoint
echo "Testing /health/simple..."
if curl -f http://localhost:8081/health/simple >/dev/null 2>&1; then
    print_status "Health endpoint is responding"
else
    print_error "Health endpoint failed"
    exit 1
fi

# Test main endpoint (should work even without database)
echo "Testing / endpoint..."
RESPONSE=$(curl -s http://localhost:8081/)
if echo "$RESPONSE" | jq . >/dev/null 2>&1; then
    print_status "Main endpoint is responding"
    DEPLOYMENT_COLOR=$(echo "$RESPONSE" | jq -r '.deployment_color // "unknown"')
    echo "  Deployment Color: $DEPLOYMENT_COLOR"
else
    print_warning "Main endpoint failed or returned invalid JSON"
    echo "Response: $RESPONSE"
fi

# Check container logs for Parameter Store access
echo ""
echo "📋 Checking container logs for Parameter Store access..."
if sudo docker logs test-parameter-store 2>&1 | grep -q "Found credentials"; then
    print_status "AWS credentials found in container"
else
    print_warning "No AWS credentials found in container logs"
fi

if sudo docker logs test-parameter-store 2>&1 | grep -q "Failed to get password from Parameter Store"; then
    print_error "Parameter Store access failed"
    echo "Container logs:"
    sudo docker logs test-parameter-store
    exit 1
else
    print_status "No Parameter Store errors found"
fi

# Show container status
echo ""
echo "📊 Container status:"
sudo docker ps --filter name=test-parameter-store

print_status "Parameter Store integration test completed successfully!"
echo ""
echo "🌐 Test application is running at: http://localhost:8081"
echo "📊 Health check: http://localhost:8081/health/simple"
echo ""
echo "To stop the test container: sudo docker stop test-parameter-store"
echo "To view logs: sudo docker logs test-parameter-store" 
#!/bin/bash

set -e

echo "🐳 Testing Flask App Containerization"
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

# Clean up any existing containers
echo "🧹 Cleaning up existing containers..."
docker compose down -v 2>/dev/null || true

# Build the Docker image
echo "🔨 Building Docker image..."
docker compose build

# Start the services
echo "🚀 Starting services..."
docker compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 30

# Test the application
echo "🧪 Testing application endpoints..."

# Test health endpoint
echo "Testing /health/simple..."
if curl -f http://localhost:8080/health/simple >/dev/null 2>&1; then
    print_status "Health endpoint is responding"
else
    print_error "Health endpoint failed"
    exit 1
fi

# Test main endpoint
echo "Testing / endpoint..."
RESPONSE=$(curl -s http://localhost:8080/)
if echo "$RESPONSE" | jq . >/dev/null 2>&1; then
    print_status "Main endpoint is responding with valid JSON"
    DEPLOYMENT_COLOR=$(echo "$RESPONSE" | jq -r '.deployment_color // "unknown"')
    CONTACTS_COUNT=$(echo "$RESPONSE" | jq '.contacts | length // 0')
    echo "  Deployment Color: $DEPLOYMENT_COLOR"
    echo "  Contacts Count: $CONTACTS_COUNT"
else
    print_error "Main endpoint failed or returned invalid JSON"
    echo "Response: $RESPONSE"
    exit 1
fi

# Test enhanced health endpoint
echo "Testing /health endpoint..."
HEALTH_RESPONSE=$(curl -s http://localhost:8080/health)
if echo "$HEALTH_RESPONSE" | jq . >/dev/null 2>&1; then
    print_status "Enhanced health endpoint is responding"
    HEALTH_STATUS=$(echo "$HEALTH_RESPONSE" | jq -r '.status // "unknown"')
    echo "  Health Status: $HEALTH_STATUS"
else
    print_error "Enhanced health endpoint failed"
    exit 1
fi

# Test info endpoint
echo "Testing /info endpoint..."
INFO_RESPONSE=$(curl -s http://localhost:8080/info)
if echo "$INFO_RESPONSE" | jq . >/dev/null 2>&1; then
    print_status "Info endpoint is responding"
    CONTAINER_ID=$(echo "$INFO_RESPONSE" | jq -r '.container_id // "unknown"')
    echo "  Container ID: $CONTAINER_ID"
else
    print_error "Info endpoint failed"
    exit 1
fi

# Test chaos endpoints
echo "Testing chaos endpoints..."
echo "  Testing /error/500..."
ERROR_500_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/error/500)
if [ "$ERROR_500_STATUS" = "500" ]; then
    print_status "500 error endpoint working correctly"
else
    print_warning "500 error endpoint returned status $ERROR_500_STATUS"
fi

echo "  Testing /error/slow..."
SLOW_RESPONSE=$(curl -s --max-time 10 http://localhost:8080/error/slow)
if echo "$SLOW_RESPONSE" | jq . >/dev/null 2>&1; then
    print_status "Slow endpoint working correctly"
else
    print_warning "Slow endpoint failed or timed out"
fi

# Show container logs
echo ""
echo "📋 Container logs (last 10 lines):"
docker compose logs --tail=10 flask-app

# Show container status
echo ""
echo "📊 Container status:"
docker compose ps

print_status "Local testing completed successfully!"
echo ""
echo "🌐 Application is running at: http://localhost:8080"
echo "📊 Health check: http://localhost:8080/health"
echo "ℹ️  Info: http://localhost:8080/info"
echo ""
echo "To stop the containers: docker compose down"
echo "To view logs: docker compose logs -f flask-app" 
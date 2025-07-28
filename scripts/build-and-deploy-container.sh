#!/bin/bash

set -e

# Configuration
ENVIRONMENT=${1:-staging}
AWS_REGION=${2:-us-east-2}
IMAGE_TAG=${3:-latest}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo "🐳 Container Build and Deploy Script"
echo "===================================="
echo "Environment: $ENVIRONMENT"
echo "AWS Region: $AWS_REGION"
echo "Image Tag: $IMAGE_TAG"
echo ""

# Check prerequisites
print_info "Checking prerequisites..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    print_error "AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

print_status "Prerequisites check passed"

# Get ECR repository URL from Terraform
print_info "Getting ECR repository URL from Terraform..."

cd environments/$ENVIRONMENT

if ! terraform output ecr_repository_url >/dev/null 2>&1; then
    print_error "ECR repository not found. Make sure ECS is enabled in $ENVIRONMENT environment."
    print_info "To enable ECS, set enable_ecs = true in terraform.tfvars"
    exit 1
fi

ECR_REPO=$(terraform output -raw ecr_repository_url)
print_status "ECR Repository: $ECR_REPO"

# Go back to root directory
cd ../..

# Build Docker image
print_info "Building Docker image..."
cd app

# Build the image
docker build -t flask-app:$IMAGE_TAG .

print_status "Docker image built successfully"

# Tag for ECR
print_info "Tagging image for ECR..."
docker tag flask-app:$IMAGE_TAG $ECR_REPO:$IMAGE_TAG

# Login to ECR
print_info "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO

# Push to ECR
print_info "Pushing image to ECR..."
docker push $ECR_REPO:$IMAGE_TAG

print_status "Image pushed to ECR successfully"

# Get ECS cluster and service information
print_info "Getting ECS service information..."

cd ../environments/$ENVIRONMENT

CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "")
BLUE_SERVICE=$(terraform output -raw blue_ecs_service_name 2>/dev/null || echo "")
GREEN_SERVICE=$(terraform output -raw green_ecs_service_name 2>/dev/null || echo "")

if [ -z "$CLUSTER_NAME" ]; then
    print_warning "ECS cluster not found. ECS may not be enabled in this environment."
    print_info "To enable ECS, set enable_ecs = true in terraform.tfvars"
    exit 0
fi

print_status "ECS Cluster: $CLUSTER_NAME"
print_status "Blue Service: $BLUE_SERVICE"
print_status "Green Service: $GREEN_SERVICE"

# Deploy to ECS
print_info "Deploying to ECS..."

# Deploy to blue service first
if [ -n "$BLUE_SERVICE" ]; then
    print_info "Deploying to blue service..."
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $BLUE_SERVICE \
        --force-new-deployment \
        --region $AWS_REGION
    
    print_status "Blue service deployment initiated"
fi

# Deploy to green service if it exists
if [ -n "$GREEN_SERVICE" ]; then
    print_info "Deploying to green service..."
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $GREEN_SERVICE \
        --force-new-deployment \
        --region $AWS_REGION
    
    print_status "Green service deployment initiated"
fi

# Wait for deployment to complete
print_info "Waiting for deployment to complete..."
sleep 30

# Check deployment status
print_info "Checking deployment status..."

if [ -n "$BLUE_SERVICE" ]; then
    BLUE_STATUS=$(aws ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $BLUE_SERVICE \
        --region $AWS_REGION \
        --query 'services[0].deployments[0].status' \
        --output text)
    
    print_info "Blue service deployment status: $BLUE_STATUS"
fi

if [ -n "$GREEN_SERVICE" ]; then
    GREEN_STATUS=$(aws ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $GREEN_SERVICE \
        --region $AWS_REGION \
        --query 'services[0].deployments[0].status' \
        --output text)
    
    print_info "Green service deployment status: $GREEN_STATUS"
fi

# Get application URL
print_info "Getting application URL..."
APP_URL=$(terraform output -raw application_url 2>/dev/null || echo "")

if [ -n "$APP_URL" ]; then
    print_status "Application URL: $APP_URL"
    print_info "Health check URL: $APP_URL/health/simple"
fi

print_status "Container build and deploy completed successfully!"
echo ""
print_info "Next steps:"
echo "  1. Monitor deployment: aws ecs describe-services --cluster $CLUSTER_NAME --services $BLUE_SERVICE"
echo "  2. Check logs: aws logs tail /aws/ecs/$ENVIRONMENT-application --follow"
echo "  3. Test application: curl $APP_URL/health/simple"
echo "  4. Switch traffic (if needed): Update ALB listener rules" 
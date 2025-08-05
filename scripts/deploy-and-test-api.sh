#!/bin/bash
#
# Deploy and Test Lambda API
# Deploys the Lambda + API Gateway infrastructure and runs tests
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/environments/terraform"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

deploy_lambda_api() {
    local workspace="${1:-dev}"
    local tfvars_file="$2"
    
    print_status "🚀 Deploying Lambda API to workspace: $workspace"
    
    cd "$TERRAFORM_DIR"
    
    # Select workspace
    terraform workspace select "$workspace" || {
        print_error "Failed to select workspace $workspace"
        exit 1
    }
    
    # Plan the deployment
    print_status "Planning terraform deployment..."
    local plan_args=""
    if [ -n "$tfvars_file" ] && [ -f "$tfvars_file" ]; then
        plan_args="-var-file=$tfvars_file"
        print_status "Using tfvars file: $tfvars_file"
    fi
    
    if ! terraform plan $plan_args -out=tfplan; then
        print_error "Terraform plan failed"
        exit 1
    fi
    
    # Apply the deployment
    print_status "Applying terraform deployment..."
    if ! terraform apply tfplan; then
        print_error "Terraform apply failed"
        exit 1
    fi
    
    print_success "Lambda API deployed successfully"
}

wait_for_api() {
    local endpoint="$1"
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for API to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$endpoint" > /dev/null 2>&1; then
            print_success "API is ready!"
            return 0
        fi
        
        print_status "Attempt $attempt/$max_attempts - API not ready yet, waiting..."
        sleep 10
        ((attempt++))
    done
    
    print_error "API failed to become ready after $max_attempts attempts"
    return 1
}

run_tests() {
    local workspace="$1"
    
    print_status "🧪 Running API tests..."
    
    cd "$TERRAFORM_DIR"
    
    # Get API endpoint
    local endpoint
    endpoint=$(terraform output -raw lambda_hello_endpoint 2>/dev/null || echo "")
    
    if [ -z "$endpoint" ]; then
        print_error "Could not get API endpoint from terraform output"
        return 1
    fi
    
    print_success "API endpoint: $endpoint"
    
    # Wait for API to be ready
    if ! wait_for_api "$endpoint"; then
        return 1
    fi
    
    # Run Python tests
    local base_url="${endpoint%/hello}"
    local test_script="$PROJECT_ROOT/lambda/hello-world/test_api.py"
    
    if [ -f "$test_script" ]; then
        print_status "Running comprehensive Python tests..."
        if python3 "$test_script" "$base_url"; then
            print_success "All tests passed!"
            return 0
        else
            print_error "Tests failed!"
            return 1
        fi
    else
        print_error "Test script not found: $test_script"
        return 1
    fi
}

cleanup() {
    print_status "Cleaning up temporary files..."
    cd "$TERRAFORM_DIR"
    rm -f tfplan
}

main() {
    local workspace="${1:-dev}"
    local tfvars_file="$2"
    local deploy_only="${3:-false}"
    
    # Validate inputs
    if [ -n "$tfvars_file" ] && [ ! -f "$TERRAFORM_DIR/$tfvars_file" ]; then
        print_error "tfvars file not found: $TERRAFORM_DIR/$tfvars_file"
        exit 1
    fi
    
    print_status "🏗️  Deploy and Test Lambda API"
    echo "=================================================="
    print_status "Workspace: $workspace"
    [ -n "$tfvars_file" ] && print_status "TFVars: $tfvars_file"
    echo "=================================================="
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Deploy
    deploy_lambda_api "$workspace" "$tfvars_file"
    
    # Test (unless deploy-only mode)
    if [ "$deploy_only" != "true" ]; then
        if run_tests "$workspace"; then
            print_success "🎉 Deployment and testing completed successfully!"
        else
            print_error "❌ Tests failed after deployment"
            exit 1
        fi
    else
        print_success "🎉 Deployment completed successfully (testing skipped)"
    fi
}

show_help() {
    echo "Usage: $0 [workspace] [tfvars-file] [deploy-only]"
    echo ""
    echo "Arguments:"
    echo "  workspace     Terraform workspace (default: dev)"
    echo "  tfvars-file   Terraform variables file (optional)"
    echo "  deploy-only   Set to 'true' to skip testing (default: false)"
    echo ""
    echo "Examples:"
    echo "  $0                              # Deploy to dev, run tests"
    echo "  $0 staging                      # Deploy to staging, run tests"
    echo "  $0 dev dev.tfvars               # Deploy to dev with tfvars, run tests"
    echo "  $0 production production.tfvars true  # Deploy to production, skip tests"
}

case "${1:-}" in
    -h|--help|help)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
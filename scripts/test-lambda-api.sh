#!/bin/bash
#
# Lambda API Testing Script
# Tests the deployed Lambda + API Gateway integration
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

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if terraform is initialized and get outputs
get_api_endpoint() {
    local workspace="${1:-dev}"
    
    print_status "Checking terraform workspace: $workspace"
    
    cd "$TERRAFORM_DIR"
    
    # Check if workspace exists
    if ! terraform workspace list | grep -q "$workspace"; then
        print_error "Terraform workspace '$workspace' not found"
        print_status "Available workspaces:"
        terraform workspace list
        exit 1
    fi
    
    # Select workspace
    terraform workspace select "$workspace" > /dev/null
    
    # Get API endpoint from terraform output
    local api_endpoint
    api_endpoint=$(terraform output -raw lambda_hello_endpoint 2>/dev/null || echo "")
    
    if [ -z "$api_endpoint" ]; then
        print_error "Could not get lambda_hello_endpoint from terraform output"
        print_status "Available outputs:"
        terraform output
        exit 1
    fi
    
    echo "$api_endpoint"
}

# Function to run basic curl tests
run_curl_tests() {
    local endpoint="$1"
    local base_url="${endpoint%/hello}"
    
    print_status "Running basic curl tests..."
    
    # Test 1: Basic hello endpoint
    print_status "Test 1: Basic hello endpoint"
    if curl -f -s "$endpoint" | jq . > /dev/null; then
        print_success "Basic hello endpoint works"
    else
        print_error "Basic hello endpoint failed"
        return 1
    fi
    
    # Test 2: Hello with name parameter
    print_status "Test 2: Hello with name parameter"
    if curl -f -s "${endpoint}?name=TestUser" | jq . > /dev/null; then
        print_success "Hello with name parameter works"
    else
        print_error "Hello with name parameter failed"
        return 1
    fi
    
    # Test 3: Check response structure
    print_status "Test 3: Checking response structure"
    local response
    response=$(curl -f -s "$endpoint")
    
    if echo "$response" | jq -e '.message' > /dev/null && \
       echo "$response" | jq -e '.timestamp' > /dev/null && \
       echo "$response" | jq -e '.lambda_function' > /dev/null; then
        print_success "Response structure is correct"
    else
        print_error "Response structure is incorrect"
        echo "Response: $response"
        return 1
    fi
    
    return 0
}

# Function to run Python tests
run_python_tests() {
    local base_url="$1"
    local test_script="$PROJECT_ROOT/lambda/hello-world/test_api.py"
    
    print_status "Running comprehensive Python tests..."
    
    # Check if Python test script exists
    if [ ! -f "$test_script" ]; then
        print_error "Python test script not found: $test_script"
        return 1
    fi
    
    # Check if requests library is available
    if ! python3 -c "import requests" 2>/dev/null; then
        print_warning "Python requests library not found, installing..."
        pip3 install requests
    fi
    
    # Run Python tests
    if python3 "$test_script" "$base_url"; then
        print_success "All Python tests passed"
        return 0
    else
        print_error "Some Python tests failed"
        return 1
    fi
}

# Function to check API Gateway logs
check_api_logs() {
    local workspace="$1"
    local function_name="${workspace}-hello-world"
    
    print_status "Checking Lambda function logs..."
    
    # Get recent log entries (last 5 minutes)
    local log_group="/aws/lambda/$function_name"
    
    if aws logs describe-log-groups --log-group-name-prefix "$log_group" --query 'logGroups[0].logGroupName' --output text 2>/dev/null | grep -q "$log_group"; then
        print_status "Recent Lambda invocations:"
        aws logs filter-log-events \
            --log-group-name "$log_group" \
            --start-time "$(($(date +%s) - 300))000" \
            --query 'events[*].[timestamp,message]' \
            --output table 2>/dev/null || print_warning "Could not fetch logs"
    else
        print_warning "Lambda log group not found or no permissions"
    fi
}

# Main function
main() {
    local workspace="${1:-dev}"
    local skip_python="${2:-false}"
    
    print_status "🚀 Starting Lambda API testing for workspace: $workspace"
    echo "=================================================="
    
    # Get API endpoint
    local endpoint
    endpoint=$(get_api_endpoint "$workspace")
    local base_url="${endpoint%/hello}"
    
    print_success "Found API endpoint: $endpoint"
    print_success "Base URL: $base_url"
    
    # Run curl tests
    if ! run_curl_tests "$endpoint"; then
        print_error "Curl tests failed"
        exit 1
    fi
    
    # Run Python tests (unless skipped)
    if [ "$skip_python" != "true" ]; then
        if ! run_python_tests "$base_url"; then
            print_error "Python tests failed"
            exit 1
        fi
    else
        print_warning "Skipping Python tests"
    fi
    
    # Check logs
    check_api_logs "$workspace"
    
    echo "=================================================="
    print_success "🎉 All API tests completed successfully!"
    print_status "API is ready for use: $endpoint"
}

# Help function
show_help() {
    echo "Usage: $0 [workspace] [skip-python]"
    echo ""
    echo "Arguments:"
    echo "  workspace     Terraform workspace to test (default: dev)"
    echo "  skip-python   Set to 'true' to skip Python tests (default: false)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Test dev workspace with all tests"
    echo "  $0 staging            # Test staging workspace with all tests"
    echo "  $0 dev true           # Test dev workspace, skip Python tests"
    echo ""
    echo "Requirements:"
    echo "  - terraform configured and initialized"
    echo "  - AWS CLI configured"
    echo "  - curl and jq installed"
    echo "  - python3 and pip3 (for Python tests)"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help|help)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
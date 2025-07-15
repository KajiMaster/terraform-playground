#!/bin/bash

# WAF Control Script for Terraform Playground
# This script allows you to easily enable/disable WAF without breaking other settings

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GLOBAL_ENV_DIR="environments/global"
WAF_MODULE_PATH="modules/waf"

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

# Function to show usage
show_usage() {
    echo "Usage: $0 {enable|disable|status}"
    echo ""
    echo "Commands:"
    echo "  enable   - Enable WAF in the global environment"
    echo "  disable  - Disable WAF in the global environment"
    echo "  status   - Show current WAF status"
    echo ""
    echo "Examples:"
    echo "  $0 enable"
    echo "  $0 disable"
    echo "  $0 status"
}

# Function to check if we're in the right directory
check_directory() {
    if [[ ! -d "$GLOBAL_ENV_DIR" ]]; then
        print_error "Global environment directory not found: $GLOBAL_ENV_DIR"
        print_error "Please run this script from the project root directory"
        exit 1
    fi
}

# Function to show WAF status
show_status() {
    print_status "Checking WAF status..."
    
    if [[ ! -f "$GLOBAL_ENV_DIR/main.tf" ]]; then
        print_error "Global environment main.tf not found"
        exit 1
    fi
    
    # Check if WAF module is configured
    if grep -q "module \"waf\"" "$GLOBAL_ENV_DIR/main.tf"; then
        print_success "WAF module is configured in global environment"
        
        # Check enable_waf setting
        if grep -q "enable_waf.*=.*true" "$GLOBAL_ENV_DIR/main.tf"; then
            print_success "WAF is ENABLED"
        elif grep -q "enable_waf.*=.*false" "$GLOBAL_ENV_DIR/main.tf"; then
            print_warning "WAF is DISABLED"
        else
            print_warning "WAF enable_waf setting not found (using default: true)"
        fi
        
        # Check logging setting
        if grep -q "enable_logging.*=.*true" "$GLOBAL_ENV_DIR/main.tf"; then
            print_success "WAF logging is ENABLED"
        elif grep -q "enable_logging.*=.*false" "$GLOBAL_ENV_DIR/main.tf"; then
            print_warning "WAF logging is DISABLED"
        else
            print_warning "WAF logging setting not found (using default: true)"
        fi
    else
        print_warning "WAF module is not configured in global environment"
    fi
}

# Function to enable WAF
enable_waf() {
    print_status "Enabling WAF..."
    
    # Check if WAF module is already configured
    if grep -q "module \"waf\"" "$GLOBAL_ENV_DIR/main.tf"; then
        # Update existing configuration
        sed -i 's/enable_waf.*=.*false/enable_waf = true/g' "$GLOBAL_ENV_DIR/main.tf"
        sed -i 's/enable_logging.*=.*false/enable_logging = true/g' "$GLOBAL_ENV_DIR/main.tf"
        print_success "Updated existing WAF configuration to enable WAF"
    else
        print_error "WAF module not found in global environment. Please add it manually first."
        exit 1
    fi
    
    print_success "WAF has been enabled"
    print_warning "Remember to run 'terraform plan' and 'terraform apply' in the global environment to apply changes"
}

# Function to disable WAF
disable_waf() {
    print_status "Disabling WAF..."
    
    # Check if WAF module is already configured
    if grep -q "module \"waf\"" "$GLOBAL_ENV_DIR/main.tf"; then
        # Update existing configuration
        sed -i 's/enable_waf.*=.*true/enable_waf = false/g' "$GLOBAL_ENV_DIR/main.tf"
        sed -i 's/enable_logging.*=.*true/enable_logging = false/g' "$GLOBAL_ENV_DIR/main.tf"
        print_success "Updated existing WAF configuration to disable WAF"
    else
        print_error "WAF module not found in global environment. Please add it manually first."
        exit 1
    fi
    
    print_success "WAF has been disabled"
    print_warning "Remember to run 'terraform plan' and 'terraform apply' in the global environment to apply changes"
}

# Main script logic
main() {
    check_directory
    
    case "$1" in
        enable)
            enable_waf
            ;;
        disable)
            disable_waf
            ;;
        status)
            show_status
            ;;
        *)
            print_error "Invalid command: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Check if command is provided
if [[ $# -eq 0 ]]; then
    print_error "No command provided"
    show_usage
    exit 1
fi

# Run main function
main "$@" 
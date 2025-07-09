#!/bin/bash
# Test script to verify path resolution
# Usage: ./scripts/test-script-paths.sh

set -e

echo "🔍 Testing Script Path Resolution..."
echo "====================================="

# Store the root directory path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Script Directory: $SCRIPT_DIR"
echo "Root Directory: $ROOT_DIR"

# Test if we can find the health checks script
if [ -f "$ROOT_DIR/scripts/test-health-checks.sh" ]; then
    echo "✅ Found test-health-checks.sh at: $ROOT_DIR/scripts/test-health-checks.sh"
else
    echo "❌ Could not find test-health-checks.sh"
fi

# Test if we can find the blue-to-green script
if [ -f "$ROOT_DIR/scripts/test-blue-to-green.sh" ]; then
    echo "✅ Found test-blue-to-green.sh at: $ROOT_DIR/scripts/test-blue-to-green.sh"
else
    echo "❌ Could not find test-blue-to-green.sh"
fi

# Test if we can find the green-to-blue script
if [ -f "$ROOT_DIR/scripts/test-green-to-blue.sh" ]; then
    echo "✅ Found test-green-to-blue.sh at: $ROOT_DIR/scripts/test-green-to-blue.sh"
else
    echo "❌ Could not find test-green-to-blue.sh"
fi

echo ""
echo "📋 Testing Environment Directory Access..."
echo "=========================================="

# Test if we can access the dev environment
if [ -d "$ROOT_DIR/environments/dev" ]; then
    echo "✅ Found dev environment directory"
    
    # Test if we can change to it
    cd "$ROOT_DIR/environments/dev"
    echo "✅ Successfully changed to dev environment directory"
    
    # Test if terraform is initialized
    if [ -d ".terraform" ]; then
        echo "✅ Terraform is initialized in dev environment"
    else
        echo "❌ Terraform is not initialized in dev environment"
    fi
else
    echo "❌ Could not find dev environment directory"
fi

echo ""
echo "🎯 Path resolution test completed!" 
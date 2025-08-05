#!/usr/bin/env python3
"""
Local testing script for Lambda function
"""
import json
from index import lambda_handler

class MockContext:
    """Mock Lambda context for testing"""
    def __init__(self):
        self.function_name = "test-function"
        self.function_version = "$LATEST"
        self.invoked_function_arn = "arn:aws:lambda:us-east-2:123456789012:function:test-function"
        self.memory_limit_in_mb = "128"
        self.remaining_time_in_millis = lambda: 30000

def test_basic_hello():
    """Test basic hello functionality"""
    event = {
        'httpMethod': 'GET',
        'path': '/hello',
        'queryStringParameters': None
    }
    
    result = lambda_handler(event, MockContext())
    body = json.loads(result['body'])
    
    print("✅ Basic Hello Test:")
    print(f"   Status: {result['statusCode']}")
    print(f"   Message: {body['message']}")
    print(f"   Math Demo: {body['math_demo']}")
    print(f"   Calculation: {body['calculation']}")
    print()

def test_with_name():
    """Test with custom name parameter"""
    event = {
        'httpMethod': 'GET',
        'path': '/hello',
        'queryStringParameters': {'name': 'Developer'}
    }
    
    result = lambda_handler(event, MockContext())
    body = json.loads(result['body'])
    
    print("✅ Custom Name Test:")
    print(f"   Status: {result['statusCode']}")
    print(f"   Message: {body['message']}")
    print(f"   Math Demo: {body['math_demo']}")
    print()

if __name__ == "__main__":
    print("🧪 Testing Lambda function locally...\n")
    test_basic_hello()
    test_with_name()
    print("🎉 All tests passed!")
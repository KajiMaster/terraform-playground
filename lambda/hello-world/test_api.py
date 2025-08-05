#!/usr/bin/env python3
"""
API Testing Framework for Lambda Hello World Endpoint
Tests the deployed API Gateway + Lambda integration
"""

import requests
import json
import sys
import time
from typing import Dict, Any, Optional

class APITester:
    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip('/')
        self.hello_endpoint = f"{self.base_url}/hello"
        self.test_results = []
        
    def run_test(self, test_name: str, test_func) -> bool:
        """Run a single test and record results"""
        print(f"Running: {test_name}")
        try:
            result = test_func()
            self.test_results.append({"test": test_name, "status": "PASS", "details": result})
            print(f"✅ PASS: {test_name}")
            return True
        except Exception as e:
            self.test_results.append({"test": test_name, "status": "FAIL", "error": str(e)})
            print(f"❌ FAIL: {test_name} - {str(e)}")
            return False
    
    def test_basic_hello(self) -> Dict[str, Any]:
        """Test basic hello endpoint"""
        response = requests.get(self.hello_endpoint, timeout=30)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        
        data = response.json()
        assert "message" in data, "Response missing 'message' field"
        assert data["message"] == "Hello, World!", f"Unexpected message: {data['message']}"
        assert "timestamp" in data, "Response missing timestamp"
        assert "lambda_function" in data, "Response missing lambda_function field"
        
        return data
    
    def test_hello_with_name(self) -> Dict[str, Any]:
        """Test hello endpoint with name parameter"""
        test_name = "APITest"
        response = requests.get(f"{self.hello_endpoint}?name={test_name}", timeout=30)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        
        data = response.json()
        expected_message = f"Hello, {test_name}!"
        assert data["message"] == expected_message, f"Expected '{expected_message}', got '{data['message']}'"
        
        return data
    
    def test_cors_headers(self) -> Dict[str, Any]:
        """Test CORS headers are present"""
        response = requests.get(self.hello_endpoint, timeout=30)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        
        headers = response.headers
        assert "Access-Control-Allow-Origin" in headers, "Missing CORS origin header"
        assert headers["Access-Control-Allow-Origin"] == "*", "CORS origin should be '*'"
        assert "Access-Control-Allow-Methods" in headers, "Missing CORS methods header"
        
        return dict(headers)
    
    def test_math_calculation(self) -> Dict[str, Any]:
        """Test the math calculation feature"""
        response = requests.get(self.hello_endpoint, timeout=30)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        
        data = response.json()
        assert "calculation" in data, "Response missing calculation field"
        assert data["calculation"] == 2, f"Expected calculation=2, got {data['calculation']}"
        assert "math_demo" in data, "Response missing math_demo field"
        
        return data
    
    def test_response_structure(self) -> Dict[str, Any]:
        """Test the complete response structure"""
        response = requests.get(self.hello_endpoint, timeout=30)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        
        data = response.json()
        required_fields = [
            "message", "math_demo", "calculation", "timestamp", 
            "method", "path", "lambda_function", "environment"
        ]
        
        for field in required_fields:
            assert field in data, f"Response missing required field: {field}"
        
        # Verify data types
        assert isinstance(data["calculation"], int), "calculation should be an integer"
        assert isinstance(data["message"], str), "message should be a string"
        assert data["method"] == "GET", "method should be GET"
        assert data["path"] == "/hello", "path should be /hello"
        
        return data
    
    def test_response_time(self) -> Dict[str, Any]:
        """Test API response time is reasonable"""
        start_time = time.time()
        response = requests.get(self.hello_endpoint, timeout=30)
        end_time = time.time()
        
        response_time = end_time - start_time
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        assert response_time < 10.0, f"Response time too slow: {response_time:.2f}s"
        
        return {"response_time_seconds": response_time}
    
    def test_multiple_requests(self) -> Dict[str, Any]:
        """Test multiple consecutive requests work properly"""
        request_count = 5
        responses = []
        
        for i in range(request_count):
            response = requests.get(f"{self.hello_endpoint}?name=Test{i}", timeout=30)
            assert response.status_code == 200, f"Request {i} failed with status {response.status_code}"
            
            data = response.json()
            assert f"Test{i}" in data["message"], f"Request {i} returned wrong message"
            responses.append(data)
        
        return {"successful_requests": request_count, "sample_response": responses[0]}
    
    def run_all_tests(self) -> Dict[str, Any]:
        """Run all API tests"""
        print(f"\n🚀 Starting API tests for: {self.hello_endpoint}")
        print("=" * 60)
        
        tests = [
            ("Basic Hello World", self.test_basic_hello),
            ("Hello with Name Parameter", self.test_hello_with_name),
            ("CORS Headers", self.test_cors_headers),
            ("Math Calculation", self.test_math_calculation),
            ("Response Structure", self.test_response_structure),
            ("Response Time", self.test_response_time),
            ("Multiple Requests", self.test_multiple_requests),
        ]
        
        passed = 0
        total = len(tests)
        
        for test_name, test_func in tests:
            if self.run_test(test_name, test_func):
                passed += 1
        
        print("\n" + "=" * 60)
        print(f"📊 Test Results: {passed}/{total} tests passed")
        
        if passed == total:
            print("🎉 All tests passed!")
            return {"status": "success", "passed": passed, "total": total, "results": self.test_results}
        else:
            print("❌ Some tests failed!")
            return {"status": "failure", "passed": passed, "total": total, "results": self.test_results}

def main():
    """Main test runner"""
    if len(sys.argv) != 2:
        print("Usage: python test_api.py <api_gateway_base_url>")
        print("Example: python test_api.py https://abc123.execute-api.us-east-2.amazonaws.com/dev")
        sys.exit(1)
    
    api_url = sys.argv[1]
    tester = APITester(api_url)
    results = tester.run_all_tests()
    
    # Exit with non-zero code if tests failed
    sys.exit(0 if results["status"] == "success" else 1)

if __name__ == "__main__":
    main()
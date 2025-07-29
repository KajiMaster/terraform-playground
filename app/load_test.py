#!/usr/bin/env python3
"""
Load Testing Script for Enterprise E-commerce API
Uses asyncio and httpx for high-performance testing
"""

import asyncio
import httpx
import time
import json
import statistics
from typing import List, Dict, Any
from faker import Faker
import argparse

fake = Faker()

class LoadTester:
    def __init__(self, base_url: str, concurrent_users: int = 10):
        self.base_url = base_url.rstrip('/')
        self.concurrent_users = concurrent_users
        self.results = []
        
    async def make_request(self, client: httpx.AsyncClient, method: str, endpoint: str, **kwargs) -> Dict[str, Any]:
        """Make a single HTTP request and measure performance"""
        start_time = time.time()
        try:
            response = await client.request(method, f"{self.base_url}{endpoint}", **kwargs)
            end_time = time.time()
            
            return {
                "method": method,
                "endpoint": endpoint,
                "status_code": response.status_code,
                "response_time": end_time - start_time,
                "success": 200 <= response.status_code < 400,
                "response_size": len(response.content) if response.content else 0
            }
        except Exception as e:
            end_time = time.time()
            return {
                "method": method,
                "endpoint": endpoint,
                "status_code": 0,
                "response_time": end_time - start_time,
                "success": False,
                "error": str(e),
                "response_size": 0
            }
    
    async def user_simulation(self, user_id: int):
        """Simulate a typical user session"""
        async with httpx.AsyncClient(timeout=30.0) as client:
            # User journey: Browse categories -> Browse products -> Get specific product -> Compute fibonacci
            requests = [
                ("GET", "/"),
                ("GET", "/health"),
                ("GET", "/categories"),
                ("GET", "/products?limit=20"),
                ("GET", "/products?category_id=1&min_price=10&max_price=100"),
                ("GET", "/products/1"),
                ("GET", "/compute/fibonacci/25"),  # CPU intensive
                ("GET", "/metrics"),
            ]
            
            for method, endpoint in requests:
                result = await self.make_request(client, method, endpoint)
                result["user_id"] = user_id
                result["timestamp"] = time.time()
                self.results.append(result)
                
                # Small delay between requests to simulate real user behavior
                await asyncio.sleep(0.1)
    
    async def create_test_data(self):
        """Create categories and products for testing"""
        async with httpx.AsyncClient(timeout=30.0) as client:
            # Create categories
            categories = [
                {"name": "Electronics", "description": "Electronic devices and gadgets"},
                {"name": "Books", "description": "Books and educational materials"},
                {"name": "Clothing", "description": "Fashion and apparel"},
                {"name": "Home & Garden", "description": "Home improvement and gardening"},
                {"name": "Sports", "description": "Sports and outdoor equipment"}
            ]
            
            category_ids = []
            for category in categories:
                try:
                    response = await client.post(f"{self.base_url}/categories", json=category)
                    if response.status_code == 200:
                        data = response.json()
                        category_ids.append(data["id"])
                except:
                    pass  # Category might already exist
                    
            # Create products
            for i in range(50):
                category_id = fake.random_element(category_ids) if category_ids else 1
                product = {
                    "name": fake.catch_phrase(),
                    "description": fake.text(max_nb_chars=200),
                    "price": round(fake.random.uniform(10.0, 500.0), 2),
                    "stock_quantity": fake.random_int(min=0, max=100),
                    "category_id": category_id,
                    "sku": fake.uuid4()[:8].upper()
                }
                
                try:
                    await client.post(f"{self.base_url}/products", json=product)
                except:
                    pass  # Product might already exist or fail validation
    
    async def run_load_test(self, duration_seconds: int = 60):
        """Run the load test for specified duration"""
        print(f"Creating test data...")
        await self.create_test_data()
        
        print(f"Starting load test with {self.concurrent_users} concurrent users for {duration_seconds} seconds...")
        start_time = time.time()
        
        while time.time() - start_time < duration_seconds:
            # Launch concurrent user sessions
            tasks = [
                self.user_simulation(user_id) 
                for user_id in range(self.concurrent_users)
            ]
            
            await asyncio.gather(*tasks)
            
            # Brief pause between waves
            await asyncio.sleep(1)
        
        print("Load test completed!")
    
    def generate_report(self) -> Dict[str, Any]:
        """Generate performance report from test results"""
        if not self.results:
            return {"error": "No test results available"}
        
        successful_requests = [r for r in self.results if r["success"]]
        failed_requests = [r for r in self.results if not r["success"]]
        
        response_times = [r["response_time"] for r in successful_requests]
        
        # Group by endpoint
        endpoint_stats = {}
        for result in self.results:
            endpoint = result["endpoint"]
            if endpoint not in endpoint_stats:
                endpoint_stats[endpoint] = {
                    "total_requests": 0,
                    "successful_requests": 0,
                    "failed_requests": 0,
                    "response_times": [],
                    "avg_response_size": 0
                }
            
            stats = endpoint_stats[endpoint]
            stats["total_requests"] += 1
            
            if result["success"]:
                stats["successful_requests"] += 1
                stats["response_times"].append(result["response_time"])
            else:
                stats["failed_requests"] += 1
        
        # Calculate endpoint statistics
        for endpoint, stats in endpoint_stats.items():
            if stats["response_times"]:
                times = stats["response_times"]
                stats.update({
                    "avg_response_time": statistics.mean(times),
                    "min_response_time": min(times),
                    "max_response_time": max(times),
                    "p95_response_time": statistics.quantiles(times, n=20)[18] if len(times) > 1 else times[0],
                    "p99_response_time": statistics.quantiles(times, n=100)[98] if len(times) > 1 else times[0]
                })
            
            stats["success_rate"] = (stats["successful_requests"] / stats["total_requests"]) * 100
        
        return {
            "summary": {
                "total_requests": len(self.results),
                "successful_requests": len(successful_requests),
                "failed_requests": len(failed_requests),
                "success_rate": (len(successful_requests) / len(self.results)) * 100,
                "avg_response_time": statistics.mean(response_times) if response_times else 0,
                "min_response_time": min(response_times) if response_times else 0,
                "max_response_time": max(response_times) if response_times else 0,
                "p95_response_time": statistics.quantiles(response_times, n=20)[18] if len(response_times) > 1 else 0,
                "p99_response_time": statistics.quantiles(response_times, n=100)[98] if len(response_times) > 1 else 0,
                "requests_per_second": len(self.results) / (max([r["timestamp"] for r in self.results]) - min([r["timestamp"] for r in self.results])) if len(self.results) > 1 else 0
            },
            "endpoint_details": endpoint_stats
        }

async def main():
    parser = argparse.ArgumentParser(description="Load test the Enterprise E-commerce API")
    parser.add_argument("--url", default="http://localhost:8080", help="Base URL of the API")
    parser.add_argument("--users", type=int, default=10, help="Number of concurrent users")
    parser.add_argument("--duration", type=int, default=60, help="Test duration in seconds")
    parser.add_argument("--output", help="Output file for results (JSON)")
    
    args = parser.parse_args()
    
    tester = LoadTester(args.url, args.users)
    
    try:
        await tester.run_load_test(args.duration)
        report = tester.generate_report()
        
        print("\n" + "="*60)
        print("LOAD TEST RESULTS")
        print("="*60)
        
        summary = report["summary"]
        print(f"Total Requests: {summary['total_requests']}")
        print(f"Successful: {summary['successful_requests']} ({summary['success_rate']:.1f}%)")
        print(f"Failed: {summary['failed_requests']}")
        print(f"Requests/sec: {summary['requests_per_second']:.1f}")
        print(f"Avg Response Time: {summary['avg_response_time']*1000:.1f}ms")
        print(f"95th Percentile: {summary['p95_response_time']*1000:.1f}ms")
        print(f"99th Percentile: {summary['p99_response_time']*1000:.1f}ms")
        
        print("\nEndpoint Performance:")
        print("-" * 60)
        for endpoint, stats in report["endpoint_details"].items():
            print(f"{endpoint:30} | {stats['success_rate']:5.1f}% | {stats.get('avg_response_time', 0)*1000:6.1f}ms")
        
        if args.output:
            with open(args.output, 'w') as f:
                json.dump(report, f, indent=2, default=str)
            print(f"\nDetailed results saved to: {args.output}")
        
    except KeyboardInterrupt:
        print("\nTest interrupted by user")
    except Exception as e:
        print(f"Test failed: {e}")

if __name__ == "__main__":
    asyncio.run(main())
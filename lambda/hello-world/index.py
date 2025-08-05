import json
import datetime

def lambda_handler(event, context):
    """
    Simple Hello World Lambda function for API Gateway integration
    """
    
    # Extract request info
    http_method = event.get('httpMethod', 'UNKNOWN')
    path = event.get('path', '/')
    query_params = event.get('queryStringParameters') or {}
    
    # Get name from query params or default
    name = query_params.get('name', 'World')
    
    # Math demonstration
    math_result = 1 + 1
    
    # Build response
    response_body = {
        'message': f'Hello, {name}!',
        'math_demo': f'1 + 1 = {math_result}',
        'calculation': math_result,
        'timestamp': datetime.datetime.utcnow().isoformat() + 'Z',
        'method': http_method,
        'path': path,
        'lambda_function': 'hello-world',
        'environment': 'fork-lambda-experiment'
    }
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        },
        'body': json.dumps(response_body)
    }
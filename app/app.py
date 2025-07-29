from flask import Flask, jsonify, request
import mysql.connector
from mysql.connector import pooling
import os
import psutil
import time
import sys
from datetime import datetime
import requests
import logging
import json
import boto3
from functools import lru_cache

app = Flask(__name__)

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler()  # Log to stdout for container logs
    ]
)
logger = logging.getLogger(__name__)

# Connection pool configuration
connection_pool_config = {
    'pool_name': 'mypool',
    'pool_size': 10,  # Adjust based on your load
    'pool_reset_session': True,
    'host': os.environ.get('DB_HOST', 'localhost'),
    'user': os.environ.get('DB_USER', 'tfplayground_user'),
    'database': os.environ.get('DB_NAME', 'tfplayground')
}

# Initialize connection pool (will be set up after getting password)
connection_pool = None

def get_container_id():
    """Get container ID from environment or generate one"""
    return os.environ.get('HOSTNAME', 'unknown')

@lru_cache(maxsize=1)
def get_db_password():
    """Get database password from Parameter Store or environment with caching"""
    # For local development, use environment variable
    if os.environ.get('DB_PASSWORD'):
        return os.environ.get('DB_PASSWORD')
    
    # For AWS deployment, use Parameter Store
    try:
        # Get region from environment or use default
        region = os.environ.get('AWS_REGION', 'us-east-2')
        
        client = boto3.client('ssm', region_name=region)
        # Use Parameter Store instead of Secrets Manager for cost optimization
        parameter_name = '/tf-playground/all/db-pword'
        response = client.get_parameter(
            Name=parameter_name,
            WithDecryption=True
        )
        
        return response['Parameter']['Value']
    except Exception as e:
        logger.error(f"Failed to get password from Parameter Store: {e}")
        return None

def initialize_connection_pool():
    """Initialize the database connection pool"""
    global connection_pool
    password = get_db_password()
    if password is None:
        logger.error("ERROR: Could not retrieve database password from Parameter Store or environment")
        sys.exit(1)
    
    connection_pool_config['password'] = password
    try:
        connection_pool = pooling.MySQLConnectionPool(**connection_pool_config)
        logger.info("Database connection pool initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize connection pool: {e}")
        sys.exit(1)

def get_db_connection():
    """Get connection from pool"""
    global connection_pool
    if connection_pool is None:
        initialize_connection_pool()
    return connection_pool.get_connection()

# Initialize connection pool at startup
initialize_connection_pool()

# Cache for table existence check
table_exists_cache = {}

def check_table_exists(table_name):
    """Check if table exists with caching"""
    if table_name in table_exists_cache:
        return table_exists_cache[table_name]
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(f"SHOW TABLES LIKE '{table_name}'")
        exists = cursor.fetchone() is not None
        cursor.close()
        conn.close()
        table_exists_cache[table_name] = exists
        return exists
    except Exception as e:
        logger.error(f"Error checking table existence: {e}")
        return False

def check_database_connection():
    """Check if database connection is working"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT 1')
        cursor.fetchone()
        cursor.close()
        conn.close()
        return True
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        return False

def check_application_readiness():
    """Check if application is ready to serve requests"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT 1')
        cursor.fetchone()
        cursor.close()
        conn.close()
        return True
    except Exception as e:
        logger.error(f"Application readiness check failed: {e}")
        return False

def check_memory_usage():
    """Check if memory usage is within acceptable limits"""
    memory = psutil.virtual_memory()
    return memory.percent < 90

def check_disk_space():
    """Check if disk space is sufficient"""
    disk = psutil.disk_usage('/')
    return disk.percent < 90

def check_response_times():
    """Check if application response times are acceptable"""
    try:
        start_time = time.time()
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT 1')
        cursor.fetchone()
        cursor.close()
        conn.close()
        response_time = time.time() - start_time
        return response_time < 2.0
    except Exception:
        return False

# Request logging middleware
@app.before_request
def log_request():
    request.start_time = time.time()

@app.after_request
def log_response(response):
    duration = time.time() - request.start_time
    
    log_data = {
        "timestamp": datetime.utcnow().isoformat(),
        "method": request.method,
        "path": request.path,
        "status_code": response.status_code,
        "duration_ms": round(duration * 1000, 2),
        "user_agent": request.headers.get('User-Agent'),
        "ip_address": request.remote_addr,
        "deployment_color": os.environ.get('DEPLOYMENT_COLOR', 'unknown'),
        "container_id": get_container_id()
    }
    
    logger.info(json.dumps(log_data))
    return response

@app.route('/')
def index():
    try:
        contacts = []
        
        # Use cached table existence check
        if check_table_exists('contacts'):
            conn = get_db_connection()
            cursor = conn.cursor(dictionary=True)
            cursor.execute('SELECT * FROM contacts')
            contacts = cursor.fetchall()
            cursor.close()
            conn.close()
        else:
            logger.info("Contacts table does not exist yet")
        
        return jsonify({
            'contacts': contacts,
            'deployment_color': os.environ.get('DEPLOYMENT_COLOR', 'unknown'),
            'timestamp': datetime.utcnow().isoformat(),
            'container_id': get_container_id(),
            'message': 'Flask application is running successfully!'
        })
    except Exception as e:
        logger.error(f"Database query failed: {str(e)}")
        return jsonify({
            'error': str(e),
            'deployment_color': os.environ.get('DEPLOYMENT_COLOR', 'unknown'),
            'timestamp': datetime.utcnow().isoformat(),
            'container_id': get_container_id(),
            'message': 'Application is running but database query failed'
        }), 500

@app.route('/health')
def health():
    """Enhanced health check endpoint"""
    try:
        # Database connectivity check
        db_status = check_database_connection()
        
        # Application readiness check
        app_status = check_application_readiness()
        
        # System health checks
        memory_status = check_memory_usage()
        disk_status = check_disk_space()
        response_status = check_response_times()
        
        # Overall health status
        all_healthy = all([db_status, app_status, memory_status, disk_status, response_status])
        
        health_data = {
            'status': 'healthy' if all_healthy else 'unhealthy',
            'checks': {
                'database_connectivity': db_status,
                'application_readiness': app_status,
                'memory_usage': memory_status,
                'disk_space': disk_status,
                'response_times': response_status
            },
            'deployment_color': os.environ.get('DEPLOYMENT_COLOR', 'unknown'),
            'timestamp': datetime.utcnow().isoformat(),
            'container_id': get_container_id()
        }
        
        logger.info(f"Health check: {json.dumps(health_data)}")
        return jsonify(health_data), 200 if all_healthy else 503
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return jsonify({
            'status': 'unhealthy',
            'error': str(e),
            'deployment_color': os.environ.get('DEPLOYMENT_COLOR', 'unknown'),
            'timestamp': datetime.utcnow().isoformat()
        }), 500

@app.route('/health/simple')
def health_simple():
    """Simple health check for load balancer target groups"""
    try:
        return jsonify({
            'status': 'healthy',
            'deployment_color': os.environ.get('DEPLOYMENT_COLOR', 'unknown'),
            'timestamp': datetime.utcnow().isoformat(),
            'container_id': get_container_id(),
            'message': 'Application is running'
        }), 200
    except Exception as e:
        logger.error(f"Simple health check failed: {str(e)}")
        return jsonify({
            'status': 'unhealthy',
            'error': str(e),
            'deployment_color': os.environ.get('DEPLOYMENT_COLOR', 'unknown'),
            'timestamp': datetime.utcnow().isoformat(),
            'container_id': get_container_id()
        }), 500

@app.route('/deployment/validate')
def deployment_validation():
    """Comprehensive validation for new deployments"""
    try:
        checks = {
            'database_connectivity': check_database_connection(),
            'application_functionality': check_application_readiness(),
            'memory_usage': check_memory_usage(),
            'disk_space': check_disk_space(),
            'response_times': check_response_times()
        }
        
        all_passed = all(checks.values())
        
        validation_data = {
            'deployment_ready': all_passed,
            'checks': checks,
            'deployment_color': os.environ.get('DEPLOYMENT_COLOR', 'unknown'),
            'timestamp': datetime.utcnow().isoformat(),
            'container_id': get_container_id()
        }
        
        logger.info(f"Deployment validation: {json.dumps(validation_data)}")
        return jsonify(validation_data), 200 if all_passed else 503
    except Exception as e:
        logger.error(f"Deployment validation failed: {str(e)}")
        return jsonify({
            'deployment_ready': False,
            'error': str(e),
            'deployment_color': os.environ.get('DEPLOYMENT_COLOR', 'unknown'),
            'timestamp': datetime.utcnow().isoformat()
        }), 500

@app.route('/info')
def info():
    """Container information endpoint"""
    try:
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        return jsonify({
            'deployment_color': os.environ.get('DEPLOYMENT_COLOR', 'unknown'),
            'container_id': get_container_id(),
            'system_info': {
                'memory_usage_percent': memory.percent,
                'disk_usage_percent': disk.percent,
                'cpu_count': psutil.cpu_count(),
                'uptime': time.time() - psutil.boot_time()
            },
            'timestamp': datetime.utcnow().isoformat()
        })
    except Exception as e:
        logger.error(f"Info endpoint failed: {str(e)}")
        return jsonify({'error': str(e)}), 500

# Chaos testing endpoints
@app.route('/error/500')
def generate_500_error():
    logger.error("Intentional 500 error generated for testing")
    return {"error": "Intentional server error"}, 500

@app.route('/error/slow')
def generate_slow_response():
    logger.warning("Intentional slow response generated for testing")
    time.sleep(3)  # Simulate slow database query
    return {"message": "Slow response completed"}

@app.route('/error/db')
def generate_db_error():
    logger.error("Intentional database error generated for testing")
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM nonexistent_table")
        cursor.fetchall()
        cursor.close()
        conn.close()
    except Exception as e:
        logger.error(f"Database error: {str(e)}")
        return {"error": "Database error", "details": str(e)}, 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080) 
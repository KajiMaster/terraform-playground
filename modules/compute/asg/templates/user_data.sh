#!/bin/bash

# Update system packages
yum update -y

# Install required packages (ADD CloudWatch agent)
yum install -y python3 python3-pip git mariadb1011-client-utils jq amazon-cloudwatch-agent

# Create application directory
mkdir -p /var/www/webapp
cd /var/www/webapp

# Create Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install required Python packages
pip install flask mysql-connector-python requests psutil boto3

# Get instance ID and set as environment variable
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
export INSTANCE_ID

# Create enhanced application files with structured logging
cat > app.py << 'EOF'
from flask import Flask, jsonify, request
import mysql.connector
import os
import psutil
import time
import sys
from datetime import datetime
import requests
import logging
import json

app = Flask(__name__)

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/flask-app.log'),
        logging.StreamHandler()  # Also log to stdout for CloudWatch
    ]
)
logger = logging.getLogger(__name__)

# Get database password from Secrets Manager
import boto3

def get_instance_id():
    """Get instance ID from metadata service"""
    try:
        import requests
        response = requests.get('http://169.254.169.254/latest/meta-data/instance-id', timeout=5)
        return response.text if response.status_code == 200 else 'unknown'
    except Exception as e:
        print(f"Failed to get instance ID: {e}")
        return 'unknown'

def get_db_password():
    try:
        # Get region from instance metadata
        import requests
        region_response = requests.get('http://169.254.169.254/latest/meta-data/placement/region', timeout=5)
        region = region_response.text if region_response.status_code == 200 else 'us-east-2'
        
        client = boto3.client('secretsmanager', region_name=region)
        # Use centralized database password secret
        secret_name = '/tf-playground/all/db-pword'
        response = client.get_secret_value(SecretId=secret_name)
        
        # The password is stored as a plain string, not JSON
        return response['SecretString']
    except Exception as e:
        print(f"Failed to get password from Secrets Manager: {e}")
        return None  # No fallback - let the application handle the error

# Database configuration
password = get_db_password()
if password is None:
    print("ERROR: Could not retrieve database password from Secrets Manager")
    sys.exit(1)

db_config = {
    'host': '${db_host}',
    'user': '${db_user}',
    'password': password,
    'database': '${db_name}'
}

def get_db_connection():
    return mysql.connector.connect(**db_config)

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
        print(f"Database connection failed: {e}")
        return False

def check_application_readiness():
    """Check if application is ready to serve requests"""
    try:
        # Just check if database is responding, don't check for specific data
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT 1')  # Simple connectivity test
        cursor.fetchone()
        cursor.close()
        conn.close()
        return True  # If we can connect and execute a query, we're ready
    except Exception as e:
        print(f"Application readiness check failed: {e}")
        return False

def check_memory_usage():
    """Check if memory usage is within acceptable limits"""
    memory = psutil.virtual_memory()
    return memory.percent < 90  # Less than 90% memory usage

def check_disk_space():
    """Check if disk space is sufficient"""
    disk = psutil.disk_usage('/')
    return disk.percent < 90  # Less than 90% disk usage

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
        return response_time < 2.0  # Less than 2 seconds
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
        "deployment_color": '${deployment_color}',
        "instance_id": get_instance_id()
    }
    
    logger.info(json.dumps(log_data))
    return response

@app.route('/')
def index():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute('SELECT * FROM contacts')
        contacts = cursor.fetchall()
        cursor.close()
        conn.close()
        return jsonify({
            'contacts': contacts,
            'deployment_color': '${deployment_color}',
            'timestamp': datetime.utcnow().isoformat(),
            'instance_id': get_instance_id()
        })
    except Exception as e:
        logger.error(f"Database query failed: {str(e)}")
        return jsonify({'error': str(e)}), 500

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
            'deployment_color': '${deployment_color}',
            'timestamp': datetime.utcnow().isoformat(),
            'instance_id': get_instance_id()
        }
        
        logger.info(f"Health check: {json.dumps(health_data)}")
        return jsonify(health_data), 200 if all_healthy else 503
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return jsonify({
            'status': 'unhealthy',
            'error': str(e),
            'deployment_color': '${deployment_color}',
            'timestamp': datetime.utcnow().isoformat()
        }), 500

@app.route('/health/simple')
def health_simple():
    """Simple health check for load balancer target groups"""
    try:
        # Basic application check - just verify the app is running
        # Don't check database or other services to keep it simple and fast
        return jsonify({
            'status': 'healthy',
            'deployment_color': '${deployment_color}',
            'timestamp': datetime.utcnow().isoformat(),
            'instance_id': get_instance_id(),
            'message': 'Application is running'
        }), 200
    except Exception as e:
        logger.error(f"Simple health check failed: {str(e)}")
        return jsonify({
            'status': 'unhealthy',
            'error': str(e),
            'deployment_color': '${deployment_color}',
            'timestamp': datetime.utcnow().isoformat(),
            'instance_id': get_instance_id()
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
            'deployment_color': '${deployment_color}',
            'timestamp': datetime.utcnow().isoformat(),
            'instance_id': get_instance_id()
        }
        
        logger.info(f"Deployment validation: {json.dumps(validation_data)}")
        return jsonify(validation_data), 200 if all_passed else 503
    except Exception as e:
        logger.error(f"Deployment validation failed: {str(e)}")
        return jsonify({
            'deployment_ready': False,
            'error': str(e),
            'deployment_color': '${deployment_color}',
            'timestamp': datetime.utcnow().isoformat()
        }), 500

@app.route('/info')
def info():
    """Instance information endpoint"""
    try:
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        return jsonify({
            'deployment_color': '${deployment_color}',
            'instance_id': get_instance_id(),
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
EOF

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/flask-app.log",
            "log_group_name": "/aws/application/staging",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/aws/ec2/staging",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Create systemd service file
cat > /etc/systemd/system/webapp.service << 'EOF'
[Unit]
Description=Python Web Application
After=network.target

[Service]
User=root
WorkingDirectory=/var/www/webapp
Environment="PATH=/var/www/webapp/venv/bin"
ExecStart=/var/www/webapp/venv/bin/python app.py
Restart=always
RestartSec=10
StandardOutput=append:/var/log/flask-app.log
StandardError=append:/var/log/flask-app.log

[Install]
WantedBy=multi-user.target
EOF

# Start and enable the service
systemctl daemon-reload
systemctl start webapp
systemctl enable webapp

# Wait for the application to start up
echo "Waiting for application to start up..." >> /var/log/webapp-deployment.log
sleep 30

# Verify the application is running
for i in {1..10}; do
    if curl -f http://localhost:8080/health/simple > /dev/null 2>&1; then
        echo "Application is running and responding to health checks" >> /var/log/webapp-deployment.log
        break
    else
        echo "Attempt $i: Application not yet ready, waiting..." >> /var/log/webapp-deployment.log
        sleep 10
    fi
done

# Create a simple health check script
cat > /usr/local/bin/health-check.sh << 'EOF'
#!/bin/bash
curl -f http://localhost:8080/health > /dev/null 2>&1
exit $?
EOF

chmod +x /usr/local/bin/health-check.sh

# Log deployment information
echo "Deployment completed for ${deployment_color} environment at $(date)" >> /var/log/webapp-deployment.log
echo "Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)" >> /var/log/webapp-deployment.log
echo "Deployment Color: ${deployment_color}" >> /var/log/webapp-deployment.log
echo "Application startup sequence completed" >> /var/log/webapp-deployment.log 
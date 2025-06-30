#!/bin/bash

# Update system packages
yum update -y

# Install required packages
yum install -y python3 python3-pip git mariadb1011-client-utils jq

# Create application directory
mkdir -p /var/www/webapp
cd /var/www/webapp

# Create Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install required Python packages
pip install flask mysql-connector-python requests psutil

# Create enhanced application files
cat > app.py << 'EOF'
from flask import Flask, jsonify, request
import mysql.connector
import os
import psutil
import time
from datetime import datetime
import requests

app = Flask(__name__)

# Database configuration
db_config = {
    'host': '${db_host}',
    'user': '${db_user}',
    'password': '${db_password}',
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
        # Basic application functionality test
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute('SELECT COUNT(*) as count FROM contacts')
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        return result['count'] >= 0  # Just check if query works
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
            'instance_id': os.environ.get('INSTANCE_ID', 'unknown')
        })
    except Exception as e:
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
        
        return jsonify({
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
            'instance_id': os.environ.get('INSTANCE_ID', 'unknown')
        }), 200 if all_healthy else 503
    except Exception as e:
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
        # Just check if the application is running and can respond
        return jsonify({
            'status': 'healthy',
            'deployment_color': '${deployment_color}',
            'timestamp': datetime.utcnow().isoformat(),
            'instance_id': os.environ.get('INSTANCE_ID', 'unknown')
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'error': str(e),
            'deployment_color': '${deployment_color}',
            'timestamp': datetime.utcnow().isoformat()
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
        
        return jsonify({
            'deployment_ready': all_passed,
            'checks': checks,
            'deployment_color': '${deployment_color}',
            'timestamp': datetime.utcnow().isoformat(),
            'instance_id': os.environ.get('INSTANCE_ID', 'unknown')
        }), 200 if all_passed else 503
    except Exception as e:
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
            'instance_id': os.environ.get('INSTANCE_ID', 'unknown'),
            'system_info': {
                'memory_usage_percent': memory.percent,
                'disk_usage_percent': disk.percent,
                'cpu_count': psutil.cpu_count(),
                'uptime': time.time() - psutil.boot_time()
            },
            'timestamp': datetime.utcnow().isoformat()
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF

# Create systemd service file
cat > /etc/systemd/system/webapp.service << 'EOF'
[Unit]
Description=Python Web Application
After=network.target

[Service]
User=root
WorkingDirectory=/var/www/webapp
Environment="PATH=/var/www/webapp/venv/bin"
Environment="INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
ExecStart=/var/www/webapp/venv/bin/python app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Start and enable the service
systemctl daemon-reload
systemctl start webapp
systemctl enable webapp

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
#!/bin/bash

# Update system packages
yum update -y

# Install required packages
yum install -y python3 python3-pip git

# Create application directory
mkdir -p /var/www/webapp
cd /var/www/webapp

# Create Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install required Python packages
pip install flask mysql-connector-python

# Create application files
cat > app.py << 'EOF'
from flask import Flask, jsonify
import mysql.connector
import os

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

@app.route('/')
def index():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute('SELECT * FROM contacts')
        contacts = cursor.fetchall()
        cursor.close()
        conn.close()
        return jsonify(contacts)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

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
ExecStart=/var/www/webapp/venv/bin/python app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start and enable the service
systemctl daemon-reload
systemctl start webapp
systemctl enable webapp 
#!/bin/bash

# Exit on error
set -e

ENVIRONMENT=$1
SECRET_NAME="/tf-playground/${ENVIRONMENT}/database/credentials"

# Get database credentials from AWS Secrets Manager
echo "Fetching database credentials from AWS Secrets Manager..."
CREDENTIALS=$(aws secretsmanager get-secret-value --secret-id "${SECRET_NAME}" --query 'SecretString' --output text)

# Extract values from the JSON
DB_HOST=$(echo "${CREDENTIALS}" | jq -r '.host')
DB_USER=$(echo "${CREDENTIALS}" | jq -r '.username')
DB_PASS=$(echo "${CREDENTIALS}" | jq -r '.password')
DB_NAME=$(echo "${CREDENTIALS}" | jq -r '.dbname')

echo "Testing database connection..."
if mysql -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" -e "SELECT 1" > /dev/null 2>&1; then
    echo "✅ Database connection successful"
    
    echo "Checking tables..."
    TABLES=$(mysql -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" -e "SHOW TABLES;" -s)
    if [ -n "$TABLES" ]; then
        echo "✅ Tables found:"
        echo "$TABLES"
        
        echo "Checking contacts table data..."
        mysql -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" -e "SELECT * FROM contacts;"
    else
        echo "❌ No tables found in database"
    fi
else
    echo "❌ Database connection failed"
fi 
#!/bin/bash

# Unified EKS Database Bootstrap Script
# Environment-agnostic script that takes environment name as argument
# Usage: ./eks-database-bootstrap.sh <environment>
# Examples: 
#   ./eks-database-bootstrap.sh dev
#   ./eks-database-bootstrap.sh staging
#   ./eks-database-bootstrap.sh ws-dev
#   ./eks-database-bootstrap.sh ws-staging
#   ./eks-database-bootstrap.sh ws-prod

AWS_REGION="us-east-2"

# Check if environment argument is provided
if [ $# -eq 0 ]; then
    echo "Error: Environment name is required"
    echo "Usage: $0 <environment>"
    echo ""
    echo "Getting available environments from global state..."
    
    # Get available environments from global state
    cd ../global
    AVAILABLE_ENVIRONMENTS=$(terraform output application_log_groups 2>/dev/null | sed -n 's/.*"\([^"]*\)" = ".*/\1/p' || echo "")
    
    if [ -z "$AVAILABLE_ENVIRONMENTS" ]; then
        echo "❌ Error: Could not access global state to get available environments"
        echo "Make sure the global environment is deployed and accessible"
        exit 1
    fi
    
    echo "Available environments:"
    echo "$AVAILABLE_ENVIRONMENTS" | tr ' ' '\n' | sed 's/^/  /'
    echo ""
    echo "Examples:"
    echo "  $0 dev"
    echo "  $0 staging"
    exit 1
fi

ENVIRONMENT="$1"

echo "EKS Database Bootstrap for Environment: $ENVIRONMENT"
echo "=================================================="
echo ""

# Get available environments from global state
cd ../global
AVAILABLE_ENVIRONMENTS=$(terraform output application_log_groups 2>/dev/null | sed -n 's/.*"\([^"]*\)" = ".*/\1/p' || echo "")

if [ -z "$AVAILABLE_ENVIRONMENTS" ]; then
    echo "❌ Error: Could not access global state to get available environments"
    echo "Make sure the global environment is deployed and accessible"
    exit 1
fi

# Check if environment exists in global state or fallback list
# Convert to newline-separated list for consistent checking
ENV_LIST=$(echo "$AVAILABLE_ENVIRONMENTS" | tr ' ' '\n')
if ! echo "$ENV_LIST" | grep -q "^$ENVIRONMENT$"; then
    echo "❌ Error: Environment '$ENVIRONMENT' not found in available environments"
    echo "Available environments:"
    echo "$ENV_LIST" | sed 's/^/  /'
    echo ""
    echo "Note: If this is a new environment, you may need to add it to the global state"
    exit 1
fi

echo "✅ Valid environment: $ENVIRONMENT"

# Switch to terraform directory and workspace
cd ../terraform

# Check if workspace exists, create if it doesn't
if ! terraform workspace list | grep -q " $ENVIRONMENT$"; then
    echo "❌ Error: Terraform workspace '$ENVIRONMENT' does not exist"
    echo "Available workspaces:"
    terraform workspace list | sed 's/^/  /'
    exit 1
fi

# Switch to the environment workspace
terraform workspace select "$ENVIRONMENT"

# Get environment-specific values from Terraform outputs
echo "Getting environment configuration from Terraform outputs..."

# Get database endpoint
DB_ENDPOINT=$(terraform output -raw database_endpoint 2>/dev/null)
if [ -z "$DB_ENDPOINT" ]; then
    echo "❌ Error: Could not get database endpoint from Terraform outputs"
    echo "Make sure the environment is deployed and has outputs available"
    exit 1
fi

# Strip port from database endpoint (MySQL expects just hostname)
DB_HOST=$(echo "$DB_ENDPOINT" | cut -d: -f1)

# Get database name
DB_NAME=$(terraform output -raw database_name 2>/dev/null)
if [ -z "$DB_NAME" ]; then
    echo "❌ Error: Could not get database name from Terraform outputs"
    exit 1
fi

# Get EKS LoadBalancer URL
EKS_URL=$(terraform output -raw eks_loadbalancer_url 2>/dev/null)
if [ -z "$EKS_URL" ]; then
    echo "❌ Error: Could not get EKS LoadBalancer URL from Terraform outputs"
    echo "Make sure EKS is enabled for this environment"
    exit 1
fi

# Get EKS cluster name
CLUSTER_NAME=$(terraform output -raw eks_cluster_name 2>/dev/null)
if [ -z "$CLUSTER_NAME" ]; then
    echo "❌ Error: Could not get EKS cluster name from Terraform outputs"
    exit 1
fi

echo "✅ Environment configuration:"
echo "  EKS Cluster: $CLUSTER_NAME"
echo "  Database: $DB_NAME"
echo "  Database Host: $DB_HOST"
echo "  EKS LoadBalancer URL: $EKS_URL"
echo ""

# Configure kubectl for the EKS cluster
echo "Configuring kubectl for EKS cluster: $CLUSTER_NAME..."
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to configure kubectl for EKS cluster"
    exit 1
fi

echo "✅ kubectl configured for EKS cluster"

# Get the pod name for the Flask app
echo "Getting Flask app pod name..."
POD_NAME=$(kubectl get pods -l app=flask-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$POD_NAME" ]; then
    echo "❌ Error: No Flask app pods found in EKS cluster"
    echo "Make sure the Flask app deployment is running"
    echo "Available pods:"
    kubectl get pods
    exit 1
fi

echo "✅ Found Flask app pod: $POD_NAME"

echo "Getting database password from Parameter Store..."
DB_PASSWORD=$(aws ssm get-parameter --name "/tf-playground/all/db-password" --region "$AWS_REGION" --with-decryption --query Parameter.Value --output text)

if [ -z "$DB_PASSWORD" ]; then
    echo "❌ Error: Could not retrieve database password from Parameter Store"
    exit 1
fi

echo "✅ Retrieved database password"

echo "Creating SQL file in pod..."
kubectl exec "$POD_NAME" -- /bin/bash -c "cat > /tmp/bootstrap-contacts.sql << 'EOF'
-- Create contacts table if it doesn't exist
CREATE TABLE IF NOT EXISTS contacts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO contacts (name, email, phone, created_at) VALUES 
    ('John Doe', 'john.doe@example.com', '+1-555-0101', NOW()),
    ('Jane Smith', 'jane.smith@example.com', '+1-555-0102', NOW()),
    ('Bob Johnson', 'bob.johnson@example.com', '+1-555-0103', NOW()),
    ('Alice Brown', 'alice.brown@example.com', '+1-555-0104', NOW()),
    ('Charlie Wilson', 'charlie.wilson@example.com', '+1-555-0105', NOW()),
    ('Diana Prince', 'diana.prince@example.com', '+1-555-0106', NOW()),
    ('Clark Kent', 'clark.kent@example.com', '+1-555-0107', NOW()),
    ('Bruce Wayne', 'bruce.wayne@example.com', '+1-555-0108', NOW()),
    ('Peter Parker', 'peter.parker@example.com', '+1-555-0109', NOW()),
    ('Tony Stark', 'tony.stark@example.com', '+1-555-0110', NOW());

-- Verify the data
SELECT COUNT(*) as contact_count FROM contacts;
EOF"

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to create SQL file in pod"
    exit 1
fi

echo "✅ Created SQL file in pod"

echo "Executing database bootstrap..."
echo "Database: $DB_NAME"
echo "Host: $DB_HOST"
echo ""

kubectl exec "$POD_NAME" -- /bin/bash -c "mysql -h $DB_HOST -u tfplayground_user -p$DB_PASSWORD $DB_NAME < /tmp/bootstrap-contacts.sql"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Database bootstrap complete!"
    echo "🌐 Check the application at: $EKS_URL"
    echo "📊 Database: $DB_NAME"
    echo "🔗 Health check: ${EKS_URL}/health/simple"
    echo "📞 Contacts endpoint: ${EKS_URL}/contacts"
    echo ""
    echo "Testing the contacts endpoint..."
    sleep 2
    CONTACT_COUNT=$(curl -s "${EKS_URL}/contacts" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "Error")
    if [ "$CONTACT_COUNT" != "Error" ] && [ "$CONTACT_COUNT" -gt 0 ]; then
        echo "✅ Success! Found $CONTACT_COUNT contacts in the database"
    else
        echo "⚠️  Note: Could not verify contacts endpoint, but database bootstrap completed"
    fi
else
    echo ""
    echo "❌ Error: Database bootstrap failed"
    exit 1
fi
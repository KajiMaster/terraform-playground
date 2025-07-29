#!/bin/bash

# Unified ECS Database Bootstrap Script
# Environment-agnostic script that takes environment name as argument
# Usage: ./ecs-database-bootstrap.sh <environment>
# Examples: 
#   ./ecs-database-bootstrap.sh staging
#   ./ecs-database-bootstrap.sh ws-dev
#   ./ecs-database-bootstrap.sh ws-staging
#   ./ecs-database-bootstrap.sh ws-prod

AWS_REGION="us-east-2"

# Check if environment argument is provided
if [ $# -eq 0 ]; then
    echo "Error: Environment name is required"
    echo "Usage: $0 <environment>"
    echo ""
    echo "Getting available environments from global state..."
    
    # Get available environments from global state
    cd /home/vex/terraform-playground/environments/global
    AVAILABLE_ENVIRONMENTS=$(terraform output -json application_log_groups 2>/dev/null | jq -r 'keys[]' 2>/dev/null || echo "staging ws-dev ws-staging ws-prod")
    
    echo "Available environments:"
    echo "$AVAILABLE_ENVIRONMENTS" | tr ' ' '\n' | sed 's/^/  /'
    echo ""
    echo "Examples:"
    echo "  $0 staging"
    echo "  $0 ws-dev"
    exit 1
fi

ENVIRONMENT="$1"

echo "ECS Database Bootstrap for Environment: $ENVIRONMENT"
echo "=================================================="
echo ""

# Get available environments from global state
cd /home/vex/terraform-playground/environments/global
AVAILABLE_ENVIRONMENTS=$(terraform output -json application_log_groups 2>/dev/null | jq -r 'keys[]' 2>/dev/null || echo "staging ws-dev ws-staging ws-prod")

# Check if environment exists in global state
if ! echo "$AVAILABLE_ENVIRONMENTS" | grep -q "^$ENVIRONMENT$"; then
    echo "❌ Error: Environment '$ENVIRONMENT' not found in global state"
    echo "Available environments:"
    echo "$AVAILABLE_ENVIRONMENTS" | tr ' ' '\n' | sed 's/^/  /'
    exit 1
fi

echo "✅ Valid environment: $ENVIRONMENT"

# Switch to terraform directory and workspace
cd /home/vex/terraform-playground/environments/terraform

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

# Get ALB URL
ALB_URL=$(terraform output -raw application_url 2>/dev/null)
if [ -z "$ALB_URL" ]; then
    echo "❌ Error: Could not get ALB URL from Terraform outputs"
    exit 1
fi

# Construct cluster name from environment
CLUSTER_NAME="${ENVIRONMENT}-ecs-cluster"

echo "✅ Environment configuration:"
echo "  Cluster: $CLUSTER_NAME"
echo "  Database: $DB_NAME"
echo "  Database Host: $DB_HOST"
echo "  ALB URL: $ALB_URL"
echo ""

echo "Getting ECS task ARN for cluster: $CLUSTER_NAME..."
TASK_ARN=$(aws ecs list-tasks --cluster "$CLUSTER_NAME" --region "$AWS_REGION" --query 'taskArns[0]' --output text)

if [ "$TASK_ARN" == "None" ] || [ -z "$TASK_ARN" ]; then
    echo "❌ Error: No ECS tasks found in cluster '$CLUSTER_NAME'"
    echo "Make sure the ECS service is running for environment: $ENVIRONMENT"
    exit 1
fi

echo "✅ Found ECS task: $TASK_ARN"

echo "Getting database password from Parameter Store..."
DB_PASSWORD=$(aws ssm get-parameter --name "/tf-playground/all/db-pword" --region "$AWS_REGION" --with-decryption --query Parameter.Value --output text)

if [ -z "$DB_PASSWORD" ]; then
    echo "❌ Error: Could not retrieve database password from Parameter Store"
    exit 1
fi

echo "✅ Retrieved database password"

echo "Creating SQL file in container..."
aws ecs execute-command \
    --cluster "$CLUSTER_NAME" \
    --task "$TASK_ARN" \
    --container flask-app \
    --interactive \
    --command "/bin/bash -c \"cat > /tmp/bootstrap-contacts.sql << 'EOF'
-- Create contacts table if it doesn't exist
CREATE TABLE IF NOT EXISTS contacts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO contacts (name, email, phone) VALUES 
    ('John Doe', 'john.doe@example.com', '+1-555-0101'),
    ('Jane Smith', 'jane.smith@example.com', '+1-555-0102'),
    ('Bob Johnson', 'bob.johnson@example.com', '+1-555-0103'),
    ('Alice Brown', 'alice.brown@example.com', '+1-555-0104'),
    ('Charlie Wilson', 'charlie.wilson@example.com', '+1-555-0105');

-- Verify the data
SELECT COUNT(*) as contact_count FROM contacts;
EOF\""

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to create SQL file in container"
    exit 1
fi

echo "✅ Created SQL file in container"

echo "Executing database bootstrap..."
echo "Database: $DB_NAME"
echo "Host: $DB_HOST"
echo ""

aws ecs execute-command \
    --cluster "$CLUSTER_NAME" \
    --task "$TASK_ARN" \
    --container flask-app \
    --interactive \
    --command "/bin/bash -c \"mysql -h $DB_HOST -u tfplayground_user -p$DB_PASSWORD $DB_NAME < /tmp/bootstrap-contacts.sql\""

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Database bootstrap complete!"
    echo "🌐 Check the application at: $ALB_URL"
    echo "📊 Database: $DB_NAME"
    echo "🔗 Health check: ${ALB_URL}health/simple"
else
    echo ""
    echo "❌ Error: Database bootstrap failed"
    exit 1
fi 
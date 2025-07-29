#!/bin/bash

# ECS Database Bootstrap One-Liner for WS-Dev
# Uses ECS Exec to run database commands from within the ECS task

echo "ECS Database Bootstrap One-Liner for WS-Dev"
echo "==========================================="
echo ""

echo "Getting ECS task ARN..."
TASK_ARN=$(aws ecs list-tasks --cluster ws-dev-ecs-cluster --region us-east-2 --query 'taskArns[0]' --output text)

if [ "$TASK_ARN" == "None" ] || [ -z "$TASK_ARN" ]; then
    echo "Error: No ECS tasks found. Make sure the ECS service is running."
    exit 1
fi

echo "Found ECS task: $TASK_ARN"

echo "Getting database password from Parameter Store..."
DB_PASSWORD=$(aws ssm get-parameter --name "/tf-playground/all/db-pword" --region us-east-2 --with-decryption --query Parameter.Value --output text)

echo "Creating SQL file in container..."
aws ecs execute-command \
    --cluster ws-dev-ecs-cluster \
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

echo "Executing database bootstrap..."
aws ecs execute-command \
    --cluster ws-dev-ecs-cluster \
    --task "$TASK_ARN" \
    --container flask-app \
    --interactive \
    --command "/bin/bash -c \"mysql -h ws-dev-db.c38ukeqk0mqb.us-east-2.rds.amazonaws.com -u tfplayground_user -p$DB_PASSWORD tfplayground_ws_dev < /tmp/bootstrap-contacts.sql\""

echo ""
echo "Database bootstrap complete!"
echo "Check the application at: http://ws-dev-alb-1132437371.us-east-2.elb.amazonaws.com/" 
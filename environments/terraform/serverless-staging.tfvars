# Staging Serverless Configuration
# This configuration demonstrates pure serverless architecture using Lambda + API Gateway
# No RDS, ASG, ECS, or EKS resources are created
environment = "staging"
aws_region  = "us-east-2"

# Network Configuration (still needed for VPC endpoints, security)
availability_zones = ["us-east-2a", "us-east-2b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

# Serverless Architecture Configuration
enable_rds = false      # Disable RDS - use DynamoDB, S3, or external services instead
enable_platform = false # Disable all platform resources (ASG/ECS/EKS/ALB)

# Platform Feature Flags (all disabled for serverless)
enable_ecs = false
enable_asg = false
enable_eks = false

# Database Configuration (not used when enable_rds = false)
db_name           = "tfplayground_staging"
db_instance_type  = "db.t3.micro"

# Compute Configuration (not used when enable_platform = false)
webserver_instance_type = "t3.micro"
ami_id                 = "ami-0c7217cdde317cfec"

# Auto Scaling Group Configuration (not used)
blue_desired_capacity = 0
blue_max_size        = 0
blue_min_size        = 0
green_desired_capacity = 0
green_max_size        = 0
green_min_size        = 0

# ECS Configuration (not used)
blue_ecs_desired_count = 0
green_ecs_desired_count = 0

# EKS Configuration (not used)
enable_node_groups = false
enable_fargate = false
enable_monitoring = false
enable_alb_controller = false

# Node group configuration (not used)
node_group_instance_types = ["t3.medium"]
node_group_desired_size = 0
node_group_max_size = 0
node_group_min_size = 0

# WAF Configuration
environment_waf_use = false

# SSL/TLS Configuration
certificate_arn = null

# Feature flags for networking (simplified for serverless)
# SERVERLESS PATTERN: Public subnets only, no NAT Gateway needed
enable_private_subnets = false  # Lambda functions run in AWS managed VPC by default
enable_nat_gateway = false      # No NAT Gateway needed for serverless
create_nat_gateway = false      # Cost optimization for serverless

# Note: With this configuration, only the following resources will be created:
# - VPC and public subnets (for VPC endpoints if needed)
# - Security groups (for VPC endpoints and potential Lambda VPC integration)
# - CloudWatch log groups (for Lambda logging)
# - Lambda functions and API Gateway (via lambda-integration.tf)
# - S3 buckets, DynamoDB tables, or other serverless services as needed
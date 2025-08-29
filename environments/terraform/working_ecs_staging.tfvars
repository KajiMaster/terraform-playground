# Staging Environment Configuration - ECS Only
# Staging-level security with cost optimization
environment = "staging"
aws_region  = "us-east-2"

# Multi-AZ for RDS and ALB
availability_zones = ["us-east-2a", "us-east-2b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]  # Private subnets for staging security

# Database Configuration (small but staging-level)
db_name           = "tfplayground_staging"
db_instance_type  = "db.t3.micro"

# Compute Configuration
webserver_instance_type = "t3.micro"
ami_id                 = "ami-0c7217cdde317cfec"  # Amazon Linux 2023

# Auto Scaling Group Configuration (disabled for ECS)
blue_desired_capacity = 1
blue_max_size        = 2
blue_min_size        = 1
green_desired_capacity = 0
green_max_size        = 2
green_min_size        = 0

# WAF Configuration (disabled for cost)
environment_waf_use = false

# ECS Configuration (ENABLED - cost-optimized staging)
enable_ecs = true
enable_asg = false  # Keep ASG disabled, ECS handles scaling

# EKS Configuration (DISABLED - ECS only)
enable_eks = false
enable_node_groups = false
enable_monitoring = true   # Enable monitoring for staging
enable_alb_controller = false

# ECS Service Configuration
blue_ecs_desired_count = 1
green_ecs_desired_count = 0

# SSL/TLS Configuration
certificate_arn = null

# Feature flags - STAGING PATTERN: Private subnets with NAT Gateway
enable_private_subnets = true   # Private subnets for security
enable_nat_gateway = true       # NAT Gateway for controlled internet access

# NAT Gateway Configuration
create_nat_gateway = true       # Enable for staging security pattern

# Test deployment after secrets modernization
enable_platform = true
enable_rds = true
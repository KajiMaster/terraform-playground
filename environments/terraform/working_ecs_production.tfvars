# Production Environment Configuration - ECS Only
# Production-level security with cost optimization
environment = "production"
aws_region  = "us-east-2"

# Multi-AZ for RDS and ALB - production reliability
availability_zones = ["us-east-2a", "us-east-2b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]  # Private subnets for production security

# Database Configuration (cost-optimized production)
db_name           = "tfplayground_production"
db_instance_type  = "db.t3.micro"  # Keep costs down

# Compute Configuration
webserver_instance_type = "t3.micro"  # Cost-optimized
ami_id                 = "ami-0c7217cdde317cfec"  # Amazon Linux 2023

# Auto Scaling Group Configuration (disabled for ECS)
blue_desired_capacity = 2    # Higher capacity for production
blue_max_size        = 4     # Can scale higher for production traffic
blue_min_size        = 1
green_desired_capacity = 0
green_max_size        = 4
green_min_size        = 0

# WAF Configuration (disabled for cost)
environment_waf_use = false

# ECS Configuration (ENABLED - production workload)
enable_ecs = true
enable_asg = false  # Keep ASG disabled, ECS handles scaling

# EKS Configuration (DISABLED - ECS only)
enable_eks = false
enable_node_groups = false
enable_monitoring = true   # Enable monitoring for production
enable_alb_controller = false

# ECS Service Configuration (production capacity)
blue_ecs_desired_count = 2   # Higher for production availability
green_ecs_desired_count = 0

# SSL/TLS Configuration (production should have SSL)
certificate_arn = null  # TODO: Add production SSL certificate

# Feature flags - PRODUCTION PATTERN: Private subnets with NAT Gateway
enable_private_subnets = true   # Private subnets for production security
enable_nat_gateway = true       # NAT Gateway for controlled internet access

# NAT Gateway Configuration
create_nat_gateway = true       # Required for production security pattern
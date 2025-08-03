# Minimal Lab Environment Configuration
# Cost: ~$2/day for basic learning and testing
environment = "lab-minimal"
aws_region  = "us-east-2"

# Single AZ for cost savings
availability_zones = ["us-east-2a"]
public_subnet_cidrs  = ["10.0.1.0/24"]
private_subnet_cidrs = []  # No private subnets for minimal tier

# Minimal compute - single instance
webserver_instance_type = "t3.micro"
blue_desired_capacity = 1
blue_max_size        = 1
blue_min_size        = 1
green_desired_capacity = 0
green_max_size        = 0
green_min_size        = 0

# Disable expensive features
create_nat_gateway = false
enable_private_subnets = false
enable_nat_gateway = false

environment_waf_use = false

# Simple ASG instead of ECS for minimal tier
enable_ecs = false
disable_asg = false

# No database for minimal tier
enable_database = false

# SSL/TLS Configuration
certificate_arn = null 
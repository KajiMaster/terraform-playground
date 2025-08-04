# Development Environment Configuration
# Cost: ~$5/day for rapid iteration and testing new components
environment = "dev"
aws_region  = "us-east-2"

# Multi-AZ for RDS and ALB (minimal cost impact)
availability_zones = ["us-east-2a", "us-east-2b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = []  # No private subnets for dev (cost savings)

# Database Configuration (small for dev)
db_name           = "tfplayground_dev"
db_instance_type  = "db.t3.micro"

# Compute Configuration
webserver_instance_type = "t3.micro"
ami_id                 = "ami-0c7217cdde317cfec"  # Amazon Linux 2023

# Auto Scaling Group Configuration (minimal)
blue_desired_capacity = 1
blue_max_size        = 1
blue_min_size        = 1
green_desired_capacity = 0
green_max_size        = 0
green_min_size        = 0

# WAF Configuration (disabled for cost)
environment_waf_use = false

# ECS Configuration (ENABLED - switching from EKS)
enable_ecs = true
enable_asg = false  # Keep ASG disabled, ECS handles scaling

# EKS Configuration (DISABLED - switching back to ECS)
enable_eks = false
enable_node_groups = false
enable_monitoring = false
enable_alb_controller = false

# ECS Service Configuration
blue_ecs_desired_count = 1
green_ecs_desired_count = 0

# SSL/TLS Configuration
certificate_arn = null

# Feature flags for cost optimization
# DEV PATTERN: Public subnets only (no NAT Gateway)
enable_private_subnets = false  # EKS nodes in public subnets
enable_nat_gateway = false      # No NAT Gateway needed


# NAT Gateway Configuration
create_nat_gateway = false      # Disable for cost savings 
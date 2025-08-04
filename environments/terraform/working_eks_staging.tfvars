# Staging Environment Configuration - EKS Only
# Staging-level security with cost optimization for Kubernetes
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

# Auto Scaling Group Configuration (disabled for EKS)
blue_desired_capacity = 1
blue_max_size        = 2
blue_min_size        = 1
green_desired_capacity = 0
green_max_size        = 2
green_min_size        = 0

# WAF Configuration (disabled for cost)
environment_waf_use = false

# ECS Configuration (DISABLED - EKS only)
enable_ecs = false
enable_asg = false  # Disable ASG since EKS handles scaling

# EKS Configuration (ENABLED - cost-optimized staging with K8s)
enable_eks = true
enable_node_groups = true
enable_fargate = false          # Use node groups for cost efficiency
enable_monitoring = true        # Enable monitoring for staging
enable_alb_controller = true    # Enable ALB controller for Kubernetes ingress

# EKS Node group configuration (cost-optimized but staging-capable)
node_group_instance_types = ["t3.small"]  # Minimum viable for Kubernetes overhead
node_group_desired_size = 2                # Cost-optimized node count
node_group_max_size = 3                    # Can scale up if needed
node_group_min_size = 1                    # Can scale down for cost savings

# ECS Service Configuration (disabled)
blue_ecs_desired_count = 0
green_ecs_desired_count = 0

# SSL/TLS Configuration
certificate_arn = null

# Feature flags - STAGING PATTERN: Private subnets with NAT Gateway
enable_private_subnets = true   # Private subnets for EKS security
enable_nat_gateway = true       # NAT Gateway for controlled internet access

# NAT Gateway Configuration
create_nat_gateway = true       # Enable for staging security pattern
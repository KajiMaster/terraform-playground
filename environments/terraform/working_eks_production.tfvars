# Production Environment Configuration - EKS Only
# Production-level security with cost-optimized Kubernetes
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

# EKS Configuration (ENABLED - cost-optimized production Kubernetes)
enable_eks = true
enable_node_groups = true
enable_fargate = false          # Use node groups for cost efficiency
enable_monitoring = true        # Enable monitoring for production
enable_alb_controller = true    # Enable ALB controller for Kubernetes ingress

# EKS Node group configuration (same as staging)
node_group_instance_types = ["t3.small"]  # Minimum viable for Kubernetes overhead
node_group_desired_size = 2                # Same as staging
node_group_max_size = 3                    # Same as staging
node_group_min_size = 1                    # Same as staging

# ECS Service Configuration (disabled)
blue_ecs_desired_count = 0
green_ecs_desired_count = 0

# Flask Application Configuration (production settings)
flask_app_replicas = 2           # Higher replica count for availability
flask_memory_request = "128Mi"   # More memory for production
flask_memory_limit = "256Mi"     # Higher limits for production
flask_cpu_request = "100m"       # More CPU for production workload
flask_cpu_limit = "200m"         # Higher CPU limits

# SSL/TLS Configuration (production should have SSL)
certificate_arn = null  # TODO: Add production SSL certificate

# Feature flags - PRODUCTION PATTERN: Private subnets with NAT Gateway
enable_private_subnets = true   # Private subnets for EKS production security
enable_nat_gateway = true       # NAT Gateway for controlled internet access

# NAT Gateway Configuration
create_nat_gateway = true       # Required for production security pattern
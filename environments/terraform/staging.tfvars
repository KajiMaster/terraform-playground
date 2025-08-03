# Staging Environment Configuration
environment = "staging"
aws_region  = "us-east-2"

# Network Configuration
availability_zones = ["us-east-2a", "us-east-2b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

# Database Configuration
db_name           = "tfplayground_staging"
db_instance_type  = "db.t3.micro"

# Compute Configuration
webserver_instance_type = "t3.micro"
ami_id                 = "ami-0c7217cdde317cfec"  # Amazon Linux 2023

# Auto Scaling Group Configuration
blue_desired_capacity = 1
blue_max_size        = 2
blue_min_size        = 1
green_desired_capacity = 0
green_max_size        = 2
green_min_size        = 0

# WAF Configuration
environment_waf_use = false

# ECS Configuration
enable_ecs = true
enable_asg = false  # Disable ASG since ECS handles scaling

# ECS Service Configuration
blue_ecs_desired_count = 1
green_ecs_desired_count = 0

# EKS Configuration (testing in staging with full complexity)
enable_eks = true
enable_node_groups = true
enable_fargate = false  # Use node groups for cost efficiency
enable_monitoring = true  # Enable monitoring in staging
enable_alb_controller = true  # Enable ALB controller for ingress

# Node group configuration (staging)
node_group_instance_types = ["t3.medium"]
node_group_desired_size = 2
node_group_max_size = 3
node_group_min_size = 1

# SSL/TLS Configuration
certificate_arn = null

# Feature flags for cost optimization
# STAGING PATTERN: Private subnets with NAT Gateway
enable_private_subnets = true   # EKS nodes in private subnets
enable_nat_gateway = true       # NAT Gateway for controlled internet access


# NAT Gateway Configuration
create_nat_gateway = true 
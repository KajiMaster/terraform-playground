# Development Environment Configuration
environment = "dev"
aws_region  = "us-east-2"

# Network Configuration
availability_zones = ["us-east-2a", "us-east-2b"]
vpc_cidr = "10.3.0.0/16"
public_subnet_cidrs  = ["10.3.1.0/24", "10.3.2.0/24"]
private_subnet_cidrs = ["10.3.10.0/24", "10.3.11.0/24"]

# Database Configuration
db_name           = "tfplayground_dev"
db_instance_type  = "db.t3.micro"

# Compute Configuration
webserver_instance_type = "t3.micro"
ami_id                 = "ami-0c7217cdde317cfec"  # Amazon Linux 2023

# Auto Scaling Group Configuration
blue_desired_capacity = 1
blue_max_size        = 1
blue_min_size        = 1
green_desired_capacity = 0
green_max_size        = 1
green_min_size        = 0

# WAF Configuration
environment_waf_use = false

# ECS Configuration
enable_ecs = true
disable_asg = true

# ECS Service Configuration
blue_ecs_desired_count = 1
green_ecs_desired_count = 0

# SSL/TLS Configuration
certificate_arn = null

# NAT Gateway Configuration
create_nat_gateway = true 
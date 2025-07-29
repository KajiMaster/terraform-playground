# Production Environment Configuration
environment = "production"

# AWS Region
aws_region = "us-east-2"

# Availability Zones
availability_zones = ["us-east-2a", "us-east-2b"]

# VPC Configuration
vpc_cidr = "10.0.0.0/16"

# Public Subnet CIDRs
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

# Private Subnet CIDRs (production-specific)
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]

# Database Configuration
db_name = "tfplayground_prod"
db_instance_type = "db.t3.micro"

# Instance Configuration
webserver_instance_type = "t3.micro"
ami_id = "ami-0c02fb55956c7d316"

# Auto Scaling Group Configuration
blue_max_size = 2
blue_min_size = 1
green_max_size = 2
green_min_size = 1

# ECS Service Configuration
blue_ecs_desired_count = 1
green_ecs_desired_count = 0

# NAT Gateway Configuration
create_nat_gateway = true

# WAF Configuration
environment_waf_use = true

# ECS Configuration
enable_ecs = true
disable_asg = true 
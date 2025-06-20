# Environment Configuration
environment = "dev"
aws_region  = "us-east-2"

# Network Configuration
vpc_cidr             = "192.1.0.0/16"
public_subnet_cidrs  = ["192.1.1.0/24", "192.1.2.0/24"]
private_subnet_cidrs = ["192.1.10.0/24", "192.1.11.0/24"]
availability_zones   = ["us-east-2a", "us-east-2b"]

# Compute Configuration
webserver_instance_type = "t3.micro"
key_name               = "tf-playground-dev"  # Replace with your key name

# Database Configuration
db_instance_type = "db.t3.micro"
db_name         = "tfplayground"
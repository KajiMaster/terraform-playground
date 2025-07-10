variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "developer" {
  description = "Developer name for individual environments (e.g., alice, bob, charlie)"
  type        = string
  default     = "default"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "172.16.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["172.16.1.0/24", "172.16.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["172.16.10.0/24", "172.16.11.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

variable "webserver_instance_type" {
  description = "Instance type for web server"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "tf-playground-dev"
}

variable "db_instance_type" {
  description = "Instance type for RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "tfplayground"
}

# Blue-Green Deployment Variables
variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS listener (optional)"
  type        = string
  default     = null
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances"
  type        = string
  default     = "ami-06c8f2ec674c67112" # Amazon Linux 2023 AMI in us-east-2
}

# Blue Auto Scaling Group Configuration
variable "blue_desired_capacity" {
  description = "Desired number of instances in the blue Auto Scaling Group"
  type        = number
  default     = 1
}

variable "blue_max_size" {
  description = "Maximum number of instances in the blue Auto Scaling Group"
  type        = number
  default     = 2
}

variable "blue_min_size" {
  description = "Minimum number of instances in the blue Auto Scaling Group"
  type        = number
  default     = 1
}

# Green Auto Scaling Group Configuration
variable "green_desired_capacity" {
  description = "Desired number of instances in the green Auto Scaling Group"
  type        = number
  default     = 0  # Start with 0 for inactive environment
}

variable "green_max_size" {
  description = "Maximum number of instances in the green Auto Scaling Group"
  type        = number
  default     = 2
}

variable "green_min_size" {
  description = "Minimum number of instances in the green Auto Scaling Group"
  type        = number
  default     = 0  # Start with 0 for inactive environment
} 
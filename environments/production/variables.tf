variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

variable "webserver_instance_type" {
  description = "EC2 instance type for web server"
  type        = string
  default     = "t3.micro"  # Production: Consider t3.small for better performance
}

variable "db_instance_type" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"  # Production: Consider db.t3.small for better performance
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "tfplayground_prod"
}

variable "key_name" {
  description = "Name of the EC2 key pair"
  type        = string
  default     = "tf-playground-key"
} 
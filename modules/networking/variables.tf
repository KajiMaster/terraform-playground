variable "environment" {
  description = "Environment name (dev, stage, prod, etc.)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

variable "azs" {
  description = "List of availability zones to use"
  type        = list(string)
} 
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
}

variable "webserver_security_group_ids" {
  description = "List of security group IDs for web servers"
  type        = list(string)
  default     = []
}

# Cost optimization variables
variable "create_nat_gateway" {
  description = "Whether to create a NAT Gateway (set to false to use shared NAT Gateway)"
  type        = bool
  default     = true
}

variable "shared_nat_gateway_id" {
  description = "ID of shared NAT Gateway to use (when create_nat_gateway is false)"
  type        = string
  default     = null
} 
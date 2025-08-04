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

# Feature flags for cost optimization
variable "enable_private_subnets" {
  description = "Enable private subnets and NAT Gateway"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway (requires private subnets)"
  type        = bool
  default     = true
}



variable "enable_eks" {
  description = "Enable EKS cluster (affects security group creation)"
  type        = bool
  default     = false
}

variable "alb_security_group_id" {
  description = "Security group ID for the Application Load Balancer"
  type        = string
  default     = null
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

variable "enable_ecs" {
  description = "Enable ECS deployment (affects security group rules)"
  type        = bool
  default     = false
}

# Variable removed - security group rules moved to individual modules

variable "enable_asg" {
  description = "Enable Auto Scaling Groups (disable when using ECS or EKS)"
  type        = bool
  default     = true
} 
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EKS cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for EKS cluster"
  type        = list(string)
}

variable "eks_nodes_security_group_id" {
  description = "Security group ID for EKS nodes"
  type        = string
  default     = ""
}

variable "eks_pods_security_group_id" {
  description = "Security group ID for EKS pods"
  type        = string
  default     = ""
}

# Feature flags for cost optimization
variable "enable_eks" {
  description = "Enable EKS cluster"
  type        = bool
  default     = false
}

variable "enable_fargate" {
  description = "Enable Fargate profiles (more expensive but serverless)"
  type        = bool
  default     = false
}

variable "enable_node_groups" {
  description = "Enable managed node groups (cheaper than Fargate)"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring for EKS"
  type        = bool
  default     = false
}

variable "enable_alb_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = false
}

# Node group configuration
variable "node_group_instance_types" {
  description = "Instance types for node groups"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 2
}

variable "node_group_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
} 
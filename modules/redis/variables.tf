variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for Redis cluster"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for Redis cluster"
  type        = string
}

variable "enable_ecs" {
  description = "Enable ECS deployment (affects security group rules)"
  type        = bool
  default     = false
}

variable "ecs_tasks_security_group_id" {
  description = "Security group ID for ECS tasks (required when enable_ecs is true)"
  type        = string
  default     = ""
}

variable "node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "num_cache_nodes" {
  description = "Number of cache nodes in the cluster"
  type        = number
  default     = 1
}

variable "auth_token" {
  description = "Auth token for Redis cluster"
  type        = string
  sensitive   = true
}
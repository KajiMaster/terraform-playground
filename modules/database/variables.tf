variable "environment" {
  description = "Deployment environment (e.g., dev, stage, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the database resources"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet IDs (used when private subnets are not available)"
  type        = list(string)
  default     = []
}

# Environment pattern variables
variable "enable_private_subnets" {
  description = "Whether private subnets are enabled (determines RDS subnet placement)"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Whether NAT Gateway is enabled (indicates enterprise pattern)"
  type        = bool
  default     = true
}



variable "db_instance_type" {
  description = "Instance type for the RDS instance"
  type        = string
}

variable "db_name" {
  description = "Name of the initial database to create"
  type        = string
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
}

variable "db_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "security_group_id" {
  description = "Security group ID for the database (managed by networking module)"
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

variable "enable_asg" {
  description = "Enable Auto Scaling Group deployment (affects security group rules)"
  type        = bool
  default     = true
}

variable "webserver_security_group_id" {
  description = "Security group ID for webservers (required when enable_asg is true)"
  type        = string
  default     = ""
}

variable "enable_eks" {
  description = "Enable EKS deployment (affects security group rules)"
  type        = bool
  default     = false
}

variable "eks_pods_security_group_id" {
  description = "Security group ID for EKS pods (required when enable_eks is true)"
  type        = string
  default     = ""
}
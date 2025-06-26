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

variable "webserver_security_group_ids" {
  description = "List of security group IDs of the webservers to allow DB access"
  type        = list(string)
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
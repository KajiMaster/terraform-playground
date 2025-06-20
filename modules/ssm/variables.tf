variable "environment" {
  description = "Environment name (dev, stage, prod, etc.)"
  type        = string
}

variable "webserver_instance_id" {
  description = "ID of the EC2 instance to run SSM commands on"
  type        = string
}

variable "webserver_public_ip" {
  description = "Public IP address of the webserver for file transfers"
  type        = string
}

variable "database_endpoint" {
  description = "RDS database endpoint"
  type        = string
}

variable "database_name" {
  description = "Database name"
  type        = string
}

variable "database_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "ssh_key_path" {
  description = "Path to the SSH private key for file transfers"
  type        = string
  default     = "~/.ssh/tf-playground-dev.pem"
}

variable "ssh_user" {
  description = "SSH user for the EC2 instance"
  type        = string
  default     = "ec2-user"
} 
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "create_resources" {
  description = "Whether to create secrets resources"
  type        = bool
  default     = true
}

variable "ssh_private_key_secret_name" {
  description = "Name of the secret containing SSH private key"
  type        = string
  default     = null
}

variable "ssh_public_key_secret_name" {
  description = "Name of the secret containing SSH public key"
  type        = string
  default     = null
}

variable "db_password_secret_name" {
  description = "Name of the secret containing database password"
  type        = string
  default     = null
}

# Note: This module expects the following resources to exist when create_resources = false:
# 1. A Secrets Manager secret at: /tf-playground/${environment}/database/credentials
#    with a JSON structure:
#    {
#      "username": "your_db_username",
#      "password": "your_db_password",
#      "engine": "mysql",
#      "host": "your_db_host",
#      "port": 3306,
#      "dbname": "your_db_name"
#    } 
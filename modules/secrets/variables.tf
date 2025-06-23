variable "environment" {
  description = "Environment name"
  type        = string
}

variable "create_resources" {
  description = "Whether to create secrets (true) or read existing ones (false)"
  type        = bool
  default     = false
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
variable "environment" {
  description = "Environment name (e.g., dev, stage, prod)"
  type        = string
}

# Note: This module expects the following resources to exist:
# 1. A KMS key with alias: alias/tf-playground-${environment}-secrets
# 2. A Secrets Manager secret at: /tf-playground/${environment}/database/credentials
#    with a JSON structure:
#    {
#      "username": "your_db_username",
#      "password": "your_db_password",
#      "engine": "mysql",
#      "host": "your_db_host",
#      "port": 3306,
#      "dbname": "your_db_name"
#    } 
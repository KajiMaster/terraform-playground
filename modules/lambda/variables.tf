variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "api_gateway_execution_arn" {
  description = "API Gateway execution ARN for Lambda permissions"
  type        = string
}
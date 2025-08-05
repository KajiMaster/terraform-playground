variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Lambda function invoke ARN"
  type        = string
}
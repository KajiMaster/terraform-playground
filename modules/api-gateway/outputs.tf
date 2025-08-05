output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = "https://${aws_api_gateway_rest_api.hello_world_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.environment}"
}

output "hello_endpoint" {
  description = "Hello endpoint URL"
  value       = "https://${aws_api_gateway_rest_api.hello_world_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.environment}/hello"
}

output "execution_arn" {
  description = "API Gateway execution ARN"
  value       = aws_api_gateway_rest_api.hello_world_api.execution_arn
}

data "aws_region" "current" {}
# Lambda + API Gateway Integration
# This file implements the hybrid serverless pattern from ADHD-PROJECT-ROADMAP.md

module "api_gateway" {
  source = "../../modules/api-gateway"
  
  environment        = var.environment
  lambda_invoke_arn  = module.lambda.invoke_arn
}

module "lambda" {
  source = "../../modules/lambda"
  
  environment               = var.environment
  api_gateway_execution_arn = module.api_gateway.execution_arn
}

# Output the endpoints for easy access
output "lambda_hello_endpoint" {
  description = "Lambda Hello World endpoint via API Gateway"
  value       = module.api_gateway.hello_endpoint
}

output "api_gateway_base_url" {
  description = "API Gateway base URL"
  value       = module.api_gateway.api_gateway_url
}
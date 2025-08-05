resource "aws_api_gateway_rest_api" "hello_world_api" {
  name        = "${var.environment}-hello-world-api"
  description = "Hello World API Gateway for ${var.environment}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "${var.environment}-hello-world-api"
    Environment = var.environment
    Project     = "terraform-playground"
    Component   = "api-gateway"
  }
}

resource "aws_api_gateway_resource" "hello_resource" {
  rest_api_id = aws_api_gateway_rest_api.hello_world_api.id
  parent_id   = aws_api_gateway_rest_api.hello_world_api.root_resource_id
  path_part   = "hello"
}

resource "aws_api_gateway_method" "hello_method" {
  rest_api_id   = aws_api_gateway_rest_api.hello_world_api.id
  resource_id   = aws_api_gateway_resource.hello_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.hello_world_api.id
  resource_id = aws_api_gateway_resource.hello_resource.id
  http_method = aws_api_gateway_method.hello_method.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = var.lambda_invoke_arn
}

resource "aws_api_gateway_method_response" "hello_response_200" {
  rest_api_id = aws_api_gateway_rest_api.hello_world_api.id
  resource_id = aws_api_gateway_resource.hello_resource.id
  http_method = aws_api_gateway_method.hello_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "hello_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.hello_world_api.id
  resource_id = aws_api_gateway_resource.hello_resource.id
  http_method = aws_api_gateway_method.hello_method.http_method
  status_code = aws_api_gateway_method_response.hello_response_200.status_code

  depends_on = [aws_api_gateway_integration.lambda_integration]
}

resource "aws_api_gateway_deployment" "hello_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration_response.hello_integration_response
  ]

  rest_api_id = aws_api_gateway_rest_api.hello_world_api.id

  lifecycle {
    create_before_destroy = true
  }

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.hello_resource.id,
      aws_api_gateway_method.hello_method.id,
      aws_api_gateway_integration.lambda_integration.id,
    ]))
  }
}

resource "aws_api_gateway_stage" "hello_stage" {
  deployment_id = aws_api_gateway_deployment.hello_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.hello_world_api.id
  stage_name    = var.environment

  tags = {
    Name        = "${var.environment}-hello-world-stage"
    Environment = var.environment
    Project     = "terraform-playground"
    Component   = "api-gateway"
  }
}
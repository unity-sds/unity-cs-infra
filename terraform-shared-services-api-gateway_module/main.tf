# Shared Services REST API Gateway
resource "aws_api_gateway_rest_api" "rest_api" {
  name        = var.rest_api_name
  description = var.rest_api_description
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# REST API Gateway root level OPTIONS method (to allow deployment with at least one method)
resource "aws_api_gateway_method" "root_level_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# REST API Gateway rot level GET method mock integration
resource "aws_api_gateway_integration" "root_level_get_method_mock_integration" {
  rest_api_id          = aws_api_gateway_rest_api.rest_api.id
  resource_id          = aws_api_gateway_rest_api.rest_api.root_resource_id
  http_method          = aws_api_gateway_method.root_level_options_method.http_method
  type                 = "MOCK"
}

# REST API ID SSM Param for other resources to modify rest api
resource "aws_ssm_parameter" "api_gateway_rest_api_id_parameter" {
  name       = format("/unity/cs/routing/shared-services-api-gateway/rest-api-id")
  type       = "String"
  value      = aws_api_gateway_rest_api.rest_api.id
  overwrite  = true
  depends_on = [aws_api_gateway_rest_api.rest_api]
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "api-gateway-deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  stage_name  = var.rest_api_stage
  depends_on = [aws_api_gateway_integration.root_level_get_method_mock_integration]
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

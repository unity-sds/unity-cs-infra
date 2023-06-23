# Shared Services REST API Gateway
resource "aws_api_gateway_rest_api" "rest_api" {
  name        = var.rest_api_name
  description = var.rest_api_description
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  body = data.template_file.api_template.rendered
}

# REST API ID SSM Param for other resources to modify rest api
resource "aws_ssm_parameter" "api_gateway_rest_api_id_parameter" {
  name       = format("/unity/cs/routing/shared-services-api-gateway/rest-api-id")
  type       = "String"
  value      = aws_api_gateway_rest_api.rest_api.id
  overwrite  = true
  depends_on = [aws_api_gateway_rest_api.rest_api]
}

# Blank OpenAPI Template
data "template_file" "api_template" {
  template = file("./unity-project-blank-api-gateway-oas.yaml")
}

resource "aws_api_gateway_deployment" "api-gateway-deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  stage_name  = var.rest_api_stage
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

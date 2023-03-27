resource "aws_api_gateway_rest_api" "rest_api" {
  name = var.rest_api_name
  description = var.rest_api_description
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  body = data.template_file.api_template.rendered
}

# REST API id SSM Param for other resources to modify rest api
resource "aws_ssm_parameter" "api_gateway_rest_api_id_parameter"{
  name       = format("/unity/%s/api-gateway/rest-api-id", var.rest_api_stage)
  type       = "String"
  value      = "${aws_api_gateway_rest_api.rest_api.id}"
  overwrite  = true
  depends_on = [aws_api_gateway_rest_api.rest_api]
}

# Auth Lambda URI
data "aws_ssm_parameter" "api_gateway_cs_lambda_authorizer_uri" {
  name = var.ssm_param_api_gateway_function_cs_lambda_authorizer_uri
}

# Auth Lambda Invoke ARN
data "aws_ssm_parameter" "api_gateway_cs_lambda_authorizer_invoke_role_arn" {
  name = var.ssm_param_api_gateway_cs_lambda_authorizer_invoke_role_arn
}

# OpenAPI Template 
data "template_file" "api_template" {
  template = file("./unity-rest-api-gateway-oas30.yaml")
  vars = {
    csLambdaAuthorizerUri = data.aws_ssm_parameter.api_gateway_cs_lambda_authorizer_uri.value
    csLambdaAuthorizerInvokeRole = data.aws_ssm_parameter.api_gateway_cs_lambda_authorizer_invoke_role_arn.value
  }
}

resource "aws_api_gateway_deployment" "api-gateway-deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  stage_name  = var.rest_api_stage
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
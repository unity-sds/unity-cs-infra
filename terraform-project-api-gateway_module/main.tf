resource "aws_api_gateway_rest_api" "rest_api" {
  name        = var.rest_api_name
  description = var.rest_api_description
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  body = data.template_file.api_template.rendered
}

# REST API id SSM Param for other resources to modify rest api
resource "aws_ssm_parameter" "api_gateway_rest_api_id_parameter" {
  name       = format("/unity/cs/routing/api-gateway/rest-api-id")
  type       = "String"
  value      = aws_api_gateway_rest_api.rest_api.id
  overwrite  = true
  depends_on = [aws_api_gateway_rest_api.rest_api]
}

# Download the Unity CS Common Auth Lambda deployment zip file
resource "null_resource" "download_lambda_zip" {
  provisioner "local-exec" {
    command = "wget --no-check-certificate ${var.unity_cs_lambda_authorizer_zip_path}  -O ucs-common-lambda-auth.zip"
  }
}

# CloudWatch Log Group for Unity CS Common Auth Lambda
resource "aws_cloudwatch_log_group" "cs_common_lambda_auth_log_group" {
  name              = "/aws/lambda/${var.unity_cs_lambda_authorizer_function_name}"
  retention_in_days = 14
}

# Unity CS Common Lambda Authorizer Execution Role ARN
data "aws_ssm_parameter" "api_gateway_cs_lambda_authorizer_invoke_role_arn" {
  name = var.ssm_param_api_gateway_cs_lambda_authorizer_invoke_role_arn
}

# Unity CS Common Lambda Authorizer Allowed Cognito Client ID List
data "aws_ssm_parameter" "api_gateway_cs_lambda_authorizer_cognito_client_id_list" {
  name = var.ssm_param_api_gateway_cs_lambda_authorizer_cognito_client_id_list
}

# Unity CS Common Lambda Authorizer Allowed Cognito User Pool ID
data "aws_ssm_parameter" "api_gateway_cs_lambda_authorizer_cognito_user_pool_id" {
  name = var.ssm_param_api_gateway_cs_lambda_authorizer_cognito_user_pool_id
}

# Unity CS Common Auth Lambda
resource "aws_lambda_function" "cs_common_lambda_auth" {
  filename      = "ucs-common-lambda-auth.zip"
  function_name = var.unity_cs_lambda_authorizer_function_name
  role          = data.aws_ssm_parameter.api_gateway_cs_lambda_authorizer_invoke_role_arn.value
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  depends_on = [null_resource.download_lambda_zip]

  environment {
    variables = {
      COGNITO_CLIENT_ID_LIST = data.aws_ssm_parameter.api_gateway_cs_lambda_authorizer_cognito_client_id_list.value
      COGNITO_USER_POOL_ID = data.aws_ssm_parameter.api_gateway_cs_lambda_authorizer_cognito_user_pool_id.value
    }
  }
}

# OpenAPI Template 
data "template_file" "api_template" {
  template = file("./unity-project-blank-api-gateway-oas.yaml")
  vars = {
    csLambdaAuthorizerUri        = aws_lambda_function.cs_common_lambda_auth.invoke_arn
    csLambdaAuthorizerInvokeRole = data.aws_ssm_parameter.api_gateway_cs_lambda_authorizer_invoke_role_arn.value
  }
}

resource "aws_api_gateway_deployment" "api-gateway-deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  stage_name  = var.rest_api_stage
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

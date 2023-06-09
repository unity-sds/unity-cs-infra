variable "region" {
  type        = string
  description = "Region"
  default     = "us-west-2"
}

variable "project_name" {
  type        = string
  description = "Project Name"
  default     = "TestProject"
}

variable "rest_api_name" {
  type        = string
  description = "REST API Name"
  default     = "Unity Project REST API Gateway"
}

variable "rest_api_description" {
  type        = string
  description = "REST API Description"
  default     = "Unity Project REST API Gateway"
}

variable "venue" {
  type        = string
  description = "Venue for deployment"
  default     = "dev"
}

variable "rest_api_stage" {
  type        = string
  description = "REST API Stage Name"
  default     = "dev"
}

variable "counter" {
  description = "value"
  type        = number
  default     = 1
}

variable "ssm_param_api_gateway_cs_lambda_authorizer_invoke_role_arn" {
  type        = string
  description = "SSM Param for API Gateway CS Lambda Authorizer Lambda Invoke Role ARN"
  default     = "/unity/dev/unity-sps-1/api-gateway/functions/cs-lambda-authorizer-invoke-role-arn"
}

variable "unity_cs_lambda_authorizer_function_name" {
  type        = string
  description = "Function name of the CS Lambda Authorizer"
  default     = "unity-cs-common-lambda-auth"
}

variable "unity_cs_lambda_authorizer_zip_path" {
  type        = string
  description = "The URL of the CS Lambda Authorizer deployment ZIP file"
  default     = "https://github.com/unity-sds/unity-cs-auth-lambda/releases/download/1.0.1/unity-cs-lambda-auth-.zip"
}

variable "ssm_param_api_gateway_cs_lambda_authorizer_cognito_client_id_list" {
  type        = string
  description = "SSM Param for API Gateway CS Lambda Authorizer Lambda Allowed Cognito Client ID List"
  default     = "/unity/dev/unity-sps-1/api-gateway/functions/cs-lambda-authorizer-cognito-client-id-list"
}

variable "ssm_param_api_gateway_cs_lambda_authorizer_cognito_user_pool_id" {
  type        = string
  description = "SSM Param for API Gateway CS Lambda Authorizer Lambda Allowed Cognito User Pool ID"
  default     = "/unity/dev/unity-sps-1/api-gateway/functions/cs-lambda-authorizer-cognito-user-pool-id"
}

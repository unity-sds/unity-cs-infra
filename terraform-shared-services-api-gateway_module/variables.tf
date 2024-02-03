variable "region" {
  type        = string
  description = "Region"
  default     = "us-west-2"
}

variable "rest_api_name" {
  type        = string
  description = "REST API Name"
  default     = "Unity Shared Services REST API Gateway"
}

variable "rest_api_description" {
  type        = string
  description = "REST API Description"
  default     = "Unity Shared Services REST API Gateway"
}

variable "venue" {
  type        = string
  description = "Venue for deployment"
  default     = "prod"
}

variable "rest_api_stage" {
  type        = string
  description = "REST API Stage Name"
  default     = "prod"
}

variable "unity_cs_api_gateway_authorizer_name" {
  type        = string
  description = "Name of the API Gateway Authorizer"
  default     = "Unity_API_Gateway_Common_Lambda_Authorizer"
}

variable "unity_cs_lambda_authorizer_function_name" {
  type        = string
  description = "Function name of the CS Lambda Authorizer"
  default     = "ucs-api-gateway-common-lambda-authorizer"
}

variable "unity_cs_lambda_authorizer_zip_path" {
  type        = string
  description = "The URL of the CS Lambda Authorizer deployment ZIP file"
  default     = "https://github.com/unity-sds/unity-cs-auth-lambda/releases/download/1.0.2/unity-cs-lambda-auth-1.0.2.zip"
}

variable "ssm_param_api_gateway_cs_lambda_authorizer_cognito_client_id_list" {
  type        = string
  description = "SSM Param for Shared Services API Gateway CS Lambda Authorizer Lambda Allowed Cognito Client ID List"
  default     = "/unity/cs/routing/shared-api-gateway/cs-lambda-authorizer-cognito-client-id-list"
}

variable "ssm_param_api_gateway_cs_lambda_authorizer_cognito_user_pool_id" {
  type        = string
  description = "SSM Param for Shared Services API Gateway CS Lambda Authorizer Lambda Allowed Cognito User Pool ID"
  default     = "/unity/cs/routing/shared-api-gateway/cs-lambda-authorizer-cognito-user-pool-id"
}

variable "ssm_param_api_gateway_cs_lambda_authorizer_cognito_user_groups_list" {
  type        = string
  description = "SSM Param for API Gateway CS Lambda Authorizer Lambda Allowed Cognito User Groups List"
  default     = "/unity/cs/routing/shared-api-gateway/cs-lambda-authorizer-cognito-user-groups-list"
}

variable "ssm_region" {
  type        = string
  description = "Region"
  default     = "/unity/shared-services/aws/account/region"
}

variable "ssm_account_id"{
  description = "Name of the SSM paramter for shared service account ID"
  type = string
  default = "/unity/shared-services/aws/account"
}

variable "tags" {
  description = "AWS Tags"
  type = map(string)
}

variable "deployment_name" {
  description = "The deployment name"
  type        = string
}
variable "project" {
  description = "The unity project its installed into"
  type = string
  default = "UnknownProject"
}

variable "venue" {
  description = "The unity venue its installed into"
  type = string
  default = "UnknownVenue"
}

variable "installprefix" {
  description = "The management console install prefix"
  type = string
  default = "UnknownPrefix"
}
variable "privatesubnets" {
  description = "Private subnets"
  type        = string
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

variable "unity_cs_lambda_authorizer_function_name" {
  type        = string
  description = "Function name of the CS Lambda Authorizer"
  default     = "unity-cs-common-lambda-authorizer"
}

variable "unity_cs_lambda_authorizer_zip_path" {
  type        = string
  description = "The URL of the CS Lambda Authorizer deployment ZIP file"
  default     = "https://github.com/unity-sds/unity-cs-auth-lambda/releases/download/1.0.3/unity-cs-lambda-auth-1.0.3.zip"
}

variable "ssm_param_api_gateway_cs_lambda_authorizer_cognito_client_id_list" {
  type        = string
  description = "SSM Param for Project Level API Gateway CS Lambda Authorizer Lambda Allowed Cognito Client ID List"
  default     = "/unity/cs/routing/venue-api-gateway/cs-lambda-authorizer-cognito-client-id-list"
}

variable "ssm_param_api_gateway_cs_lambda_authorizer_cognito_user_pool_id" {
  type        = string
  description = "SSM Param for Project Level API Gateway CS Lambda Authorizer Lambda Allowed Cognito User Pool ID"
  default     = "/unity/cs/routing/venue-api-gateway/cs-lambda-authorizer-cognito-user-pool-id"
}

variable "ssm_param_api_gateway_cs_lambda_authorizer_cognito_user_groups_list" {
  type        = string
  description = "SSM Param for API Gateway CS Lambda Authorizer Lambda Allowed Cognito User Groups List"
  default     = "/unity/cs/routing/venue-api-gateway/cs-lambda-authorizer-cognito-user-groups-list"
}

variable "ssm_param_api_gateway_cs_lambda_authorizer_invoke_role_arn" {
  type        = string
  description = "SSM Param for API Gateway CS Lambda Authorizer Lambda Invoke Role ARN"
  default     = "/unity/cs/routing/venue-api-gateway/cs-lambda-authorizer-invoke-role-arn"
}

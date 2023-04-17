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
  description = "REST API Stage"
  default     = "dev"
}

variable "rest_api_stage" {
  type = string
  description = "REST API Stage"
  default = var.venue
}

variable "counter" {
  description = "value"
  type        = number
  default     = 1
}

variable "ssm_param_api_gateway_function_cs_lambda_authorizer_uri" {
  type        = string
  description = "SSM Param for API Gateway CS Lambda Authorizer Function URI"
  default     = "/unity/dev/unity-sps-1/api-gateway/functions/cs-lambda-authorizer-uri"
}

variable "ssm_param_api_gateway_cs_lambda_authorizer_invoke_role_arn" {
  type        = string
  description = "SSM Param for API Gateway CS Lambda Authorizer Lambda Invoke Role ARN"
  default     = "/unity/dev/unity-sps-1/api-gateway/functions/cs-lambda-authorizer-invoke-role-arn"
}

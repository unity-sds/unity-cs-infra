variable "rest_api_name" {
  type        = string
  description = "REST API Name"
  default     = "Unity REST API Gateway - Do Not Update Manually"
}

variable "rest_api_description" {
  type        = string
  description = "REST API Description"
  default     = "Primary Unity REST API Gateway - Do Not Update Manually - Terraform Created - Contact Unity CS Team"
}

variable "rest_api_stage" {
  type        = string
  description = "REST API Stage"
  default     = "dev"
}

variable "namespace" {
  description = "Namespace for the Unity SPS HySDS-related Kubernetes resources"
  type        = string
  default     = "unity-sps"
}

variable "counter" {
  description = "value"
  type        = number
  default     = 1
}

# -----------------------------------------------------------------
# SSM Params
# -----------------------------------------------------------------

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

variable "ssm_param_api_gateway_integration_uads_dockstore_nlb_uri" {
  type        = string
  description = "SSM Param for UADS Dockstore NLB URI"
  default     = "/unity/dev/unity-sps-1/api-gateway/integrations/uads-dockstore-nlb-uri"
}

variable "ssm_param_api_gateway_integration_uads_dockstore_link_2_vpc_link_id" {
  type        = string
  description = "SSM Param for UADS Dockstore Link 2 VPC Link Id"
  default     = "/unity/dev/unity-sps-1/api-gateway/integrations/uads-dev-dockstore-link-2-vpc-link-id"
}

variable "ssm_param_api_gateway_integration_uds_granules_dapa_function_name" {
  type        = string
  description = "SSM Param for UDS Granules DAPA Function Name"
  default     = "/unity/unity-ds/api-gateway/integrations/granules-dapa-function-name"
}

variable "ssm_param_api_gateway_integration_uds_collections_dapa_function_name" {
  type        = string
  description = "SSM Param for UDS Collections DAPA Function Name"
  default     = "/unity/unity-ds/api-gateway/integrations/collections-dapa-function-name"
}

variable "ssm_param_api_gateway_integration_uds_collections_create_dapa_function_name" {
  type        = string
  description = "SSM Param for UDS Collections Creation DAPA Function Name"
  default     = "/unity/unity-ds/api-gateway/integrations/collections-create-dapa-function-name"
}

variable "api_gateway_integration_cumulus_auth_add_function_name" {
  type        = string
  description = "SSM Param for UDS Collections Ingestion DAPA Function Name"
  default     = "/unity/unity-ds/api-gateway/integrations/collections-ingest-dapa-function-name"
}

variable "ssm_param_api_gateway_integration_uds_collections_ingest_dapa_function_name" {
  type        = string
  description = "SSM Param for UDS Collections Ingestion DAPA Function Name"
  default     = "/unity/unity-ds/api-gateway/integrations/collections-ingest-dapa-function-name"
}

variable "ssm_param_api_gateway_integration_uds_setup_es_function_name_function_name" {
  type        = string
  description = "SSM Param for UDS Setup ES Function Name"
  default     = "/unity/unity-ds/api-gateway/integrations/cumulus_es_setup_index_alias-function-name"
}
variable "ssm_param_api_gateway_integration_uds_auth_add_function_name_function_name" {
  type        = string
  description = "SSM Param for UDS Authorization Record Addition Function Name"
  default     = "/unity/unity-ds/api-gateway/integrations/cumulus_auth_add-function-name"
}
variable "ssm_param_api_gateway_integration_uds_auth_list_function_name_function_name" {
  type        = string
  description = "SSM Param for UDS Authorization Record Listing Function Name"
  default     = "/unity/unity-ds/api-gateway/integrations/cumulus_auth_list-function-name"
}
variable "ssm_param_api_gateway_integration_uds_auth_delete_function_name_function_name" {
  type        = string
  description = "SSM Param for Authorization Record Deletion Function Name"
  default     = "/unity/unity-ds/api-gateway/integrations/cumulus_auth_delete-function-name"
}

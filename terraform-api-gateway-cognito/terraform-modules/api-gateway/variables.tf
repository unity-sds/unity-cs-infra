variable "rest_api_name" {
  type        = string
  description = "REST API Name"
  default     = "Unity CS Experimental REST API Gateway"
}

# -----------------------------------------------------------------
# SSM Params
# -----------------------------------------------------------------

variable "ssm_param_api_gateway_function_cs_lambda_authorizer_uri" {
  type        = string
  description = "SSM Param for API Gateway CS Lambda Authorizer Function URI"
  default     = "/unity/dev/unity-sps-1/api-gateway/functions/cs-lambda-authorizer-uri"
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

variable "ssm_param_api_gateway_integration_uds_dev_cumulus_cumulus_granules_dapa_function_uri" {
  type        = string
  description = "SSM Param for UDS Dev Cumulus Cumulus Granules DAPA Function URI"
  default     = "/unity/dev/unity-sps-1/api-gateway/integrations/uds-dev-cumulus-cumulus_granules_dapa-function-uri"
}

variable "ssm_param_api_gateway_integration_uds_dev_cumulus_cumulus_collections_dapa_function_uri" {
  type        = string
  description = "SSM Param for UDS Dev Cumulus Cumulus Collections DAPA Function URI"
  default     = "/unity/dev/unity-sps-1/api-gateway/integrations/uds-dev-cumulus-cumulus_collections_dapa-function-uri"
}

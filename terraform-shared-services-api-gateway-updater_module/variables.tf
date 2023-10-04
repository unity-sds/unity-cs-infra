variable "region" {
  type        = string
  description = "Region"
  default     = "us-west-2"
}

variable "shared_services_rest_api_name" {
  type        = string
  description = "Shared services REST API name"
  default     = "Unity Shared Services REST API Gateway"
}

#
# Overwrite the default value below with the project-level API Gateway, including the stage.
# This is the the API Gateway route that automatically gets created by the 
# Management Console when it boots up for the first time.
# This represents the main entry point from the shared services API Gateway,
# into the project-level API Gateway stage.
#
# This will create route under the project resource (this is created in main.tf)
#
variable "sample_rest_api_integration_uri" {
  type = string
  description = "Sample REST API Integration URI"
  default = "https://sample-rest-api-id.execute-api.us-west-2.amazonaws.com/dev/{proxy}"
}

variable "sample_website_integration_uri" {
  type = string
  description = "Sample Website Integration URI"
  default = "https://www.wikipedia.org"
}

variable "rest_api_stage" {
  type        = string
  description = "REST API Stage Name"
  default     = "dev"
}

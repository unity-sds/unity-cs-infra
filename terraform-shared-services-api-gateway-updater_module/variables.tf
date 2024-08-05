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
# Overwrite the default value below with the project-level API Gateway values, including the stage.
# This is the the API Gateway route that automatically gets created by the 
# Management Console when it boots up for the first time.
# This represents the main entry point from the shared services API Gateway,
# into the project-level API Gateway stage.
#
# This will create a project level resource under the root level of API Gateway(this is created in main.tf)
#

# Specify a name to identify the project name that this resource is pointing to.
variable "resource_for_project" {
  type = string
  description = "An API Gateway resource to identify the Project Name that this specific resource is integrated with"
  default = "unity-example-project-test"
}

# Specify the URL of the project level API gateway root level with stage name (E.g.: dev) and {proxy} in the URL below.
# E.g.: If the URL of the project level API Gateway is https://example-rest-api-id.execute-api.us-west-2.amazonaws.com/ then
# this variable should have the value https://example-rest-api-id.execute-api.us-west-2.amazonaws.com/dev/{proxy}
variable "project_leveL_rest_api_integration_uri" {
  type = string
  description = "URL of the project level API gateway to be integrated with"
  default = "https://<API-Gateway-Id>.execute-api.us-west-2.amazonaws.com/dev/{proxy}"
}

# The deployment stage of the Shared Services API Gateway
variable "rest_api_stage" {
  type        = string
  description = "REST API Stage Name"
  default     = "dev"
}


# The following variable is commented out, because it is not required for RESTful APIs
# variable "sample_website_integration_uri" {
#   type = string
#   description = "Sample Website Integration URI"
#   default = "https://www.wikipedia.org"
# }

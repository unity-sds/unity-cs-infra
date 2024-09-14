
# Reference to the REST API to be updated
data "aws_api_gateway_rest_api" "rest_api" {

  # Name of the REST API to look up. If no REST API is found with this name, an error will be returned. 
  # If multiple REST APIs are found with this name, an error will be returned. At the moment there is noi data source to 
  # get REST API by ID.
  name = var.shared_services_rest_api_name
}

# 
# Creates the project API Gateway resource to be pointed to a project level API gateway.
# DEPLOYER SHOULD MODIFY THE VARIABLE var.resource_for_project TO BE THE PROJECT NAME (e.g. "soundersips")
resource "aws_api_gateway_resource" "rest_api_resource_for_project" {
  rest_api_id = data.aws_api_gateway_rest_api.rest_api.id
  parent_id   = data.aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = var.resource_for_project
}

#
# Creates the wildcard path (proxy+) resource, under the project resource 
#
resource "aws_api_gateway_resource" "rest_api_resource_for_project_proxy_resource" {
  rest_api_id = data.aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_resource.rest_api_resource_for_project.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "rest_api_method_for_project_proxy_resource_method" {
  rest_api_id   = data.aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.rest_api_resource_for_project_proxy_resource.id
  http_method   = "ANY"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "rest_api_resource_for_project_proxy_resource_method_integration" {
  rest_api_id   = data.aws_api_gateway_rest_api.rest_api.id
  resource_id          = aws_api_gateway_resource.rest_api_resource_for_project_proxy_resource.id
  http_method          = aws_api_gateway_method.rest_api_method_for_project_proxy_resource_method.http_method
  type                 = "HTTP_PROXY"
  uri                  = var.project_leveL_rest_api_integration_uri
  integration_http_method = "ANY"

  cache_key_parameters = ["method.request.path.proxy"]

  timeout_milliseconds = 29000
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

}

resource "aws_api_gateway_method" "rest_api_get_options_method" {
  rest_api_id   = data.aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.rest_api_resource_for_project.id
  http_method   = "OPTIONS"
  authorization = "NONE"
  request_parameters = {"method.request.header.Authorization" = true}
}

resource "aws_api_gateway_integration" "sample_rest_api_get_method_integration" {
  rest_api_id = data.aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.rest_api_resource_for_project.id
  http_method = aws_api_gateway_method.rest_api_get_options_method.http_method

  type        = "MOCK"
}

# The Shared Services API Gateway deployment
resource "aws_api_gateway_deployment" "shared_services_api_gateway_deployment" {
  rest_api_id = data.aws_api_gateway_rest_api.rest_api.id
  stage_name        = var.rest_api_stage
  stage_description = "Deployed at ${timestamp()}"

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [ aws_api_gateway_integration.rest_api_resource_for_project_proxy_resource_method_integration ]
}



# The following section is commented out, because it is not required for RESTful APIs

/*
# Sample Website Proxy
resource "aws_api_gateway_resource" "sample_website" {
  rest_api_id = data.aws_api_gateway_rest_api.rest_api.id
  parent_id   = data.aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "sample_website"
}

resource "aws_api_gateway_method" "sample_website_get_method" {
  rest_api_id   = data.aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.sample_website.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "sample_website_get_method_integration" {
  rest_api_id = data.aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.sample_website.id
  http_method = aws_api_gateway_method.sample_website_get_method.http_method

  type                    = "HTTP"
  uri                     = var.sample_website_integration_uri
  integration_http_method = "GET"
}

resource "aws_api_gateway_method_response" "sample_website_get_method_response_200" {
  rest_api_id = data.aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.sample_website.id
  http_method = aws_api_gateway_method.sample_website_get_method.http_method
  status_code = "200"

  response_models = {
    "text/html" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "sample_website_get_method_integration_response" {
  rest_api_id = data.aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.sample_website.id
  http_method = aws_api_gateway_method.sample_website_get_method.http_method
  status_code = aws_api_gateway_method_response.sample_website_get_method_response_200.status_code

  response_templates = {"text/html": "$input.path('$')"}
}

resource "aws_api_gateway_deployment" "api-gateway-deployment" {
  rest_api_id = data.aws_api_gateway_rest_api.rest_api.id
  stage_name  = var.rest_api_stage
}

*/

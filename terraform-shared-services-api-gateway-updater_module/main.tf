
# Reference to the REST API to be updated
data "aws_api_gateway_rest_api" "rest_api" {
  name = var.shared_services_rest_api_name
}

# Sample REST API Proxy
resource "aws_api_gateway_resource" "sample_rest_api_resource" {
  rest_api_id = data.aws_api_gateway_rest_api.rest_api.id
  parent_id   = data.aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "sample_rest_api"
}

resource "aws_api_gateway_resource" "sample_rest_api_proxy_resource" {
  rest_api_id = data.aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_resource.sample_rest_api_resource.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "sample_rest_api_proxy_resource_method" {
  rest_api_id   = data.aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.sample_rest_api_proxy_resource.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "sample_rest_api_proxy_resource_method_integration" {
  rest_api_id   = data.aws_api_gateway_rest_api.rest_api.id
  resource_id          = aws_api_gateway_resource.sample_rest_api_proxy_resource.id
  http_method          = aws_api_gateway_method.sample_rest_api_proxy_resource_method.http_method
  type                 = "HTTP_PROXY"
  uri                  = var.sample_rest_api_integration_uri
  integration_http_method = "GET"

  cache_key_parameters = ["method.request.path.proxy"]

  timeout_milliseconds = 29000
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

}

resource "aws_api_gateway_method" "sample_rest_api_get_method" {
  rest_api_id   = data.aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.sample_rest_api_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
  request_parameters = {"method.request.header.Authorization" = true}
}

resource "aws_api_gateway_integration" "sample_rest_api_get_method_integration" {
  rest_api_id = data.aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.sample_rest_api_resource.id
  http_method = aws_api_gateway_method.sample_rest_api_get_method.http_method

  type        = "MOCK"
}


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

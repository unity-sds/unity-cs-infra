resource "aws_api_gateway_rest_api" "rest_api" {
  name = var.rest_api_name
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  body = data.template_file.api_template.rendered
}

data "aws_ssm_parameter" "api_gateway_cs_lambda_authorizer_uri" {
  name = var.ssm_param_api_gateway_function_cs_lambda_authorizer_uri
}

data "aws_ssm_parameter" "api_gateway_integration_uads_dockstore_nlb_uri" {
  name = var.ssm_param_api_gateway_integration_uads_dockstore_nlb_uri
}

data "aws_ssm_parameter" "api_gateway_integration_uads_dockstore_link_2_vpc_link_id" {
  name = var.ssm_param_api_gateway_integration_uads_dockstore_link_2_vpc_link_id
}

data "aws_ssm_parameter" "api_gateway_integration_uds_dev_cumulus_cumulus_granules_dapa_function_uri" {
  name = var.ssm_param_api_gateway_integration_uds_dev_cumulus_cumulus_granules_dapa_function_uri
}

data "aws_ssm_parameter" "api_gateway_integration_uds_dev_cumulus_cumulus_collections_dapa_function_uri" {
  name = var.ssm_param_api_gateway_integration_uds_dev_cumulus_cumulus_collections_dapa_function_uri
}

data "template_file" "api_template" {
  template = file("./terraform-modules/api-gateway/unity-rest-api-gateway-oas30.yaml")

  vars = {
    csLambdaAuthorizerUri = data.aws_ssm_parameter.api_gateway_cs_lambda_authorizer_uri.value
    uadsDockstoreNlbUri = data.aws_ssm_parameter.api_gateway_integration_uads_dockstore_nlb_uri.value
    uadsDockstoreLink2VpcLinkId = data.aws_ssm_parameter.api_gateway_integration_uads_dockstore_link_2_vpc_link_id.value
    udsDevCumulusCumulusGranulesDapaFunctionUri = data.aws_ssm_parameter.api_gateway_integration_uds_dev_cumulus_cumulus_granules_dapa_function_uri.value
    udsDevCumulusCumulusCumulusCollectionsDapaFunctionUri = data.aws_ssm_parameter.api_gateway_integration_uds_dev_cumulus_cumulus_collections_dapa_function_uri.value
  }
}

resource "aws_api_gateway_deployment" "api-gateway-deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  stage_name  = "dev"

  variables = {
    adesWpstUrl      = "-",
    grqEsUrl         = "-",
    grqRestApiUrl    = "-",
    hysdsUiUrl       = "-",
    mozartEsUrl      = "-",
    mozartRestApiUrl = "-"
  }
}

output "url" {
  value = "${aws_api_gateway_deployment.api-gateway-deployment.invoke_url}/api"
}
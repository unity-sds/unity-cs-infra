module "api_gateway" {
  source = "./terraform-modules/api-gateway"
}

module "cognito_user_pool" {
  source = "./terraform-modules/cognito-user-pool"
}

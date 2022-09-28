resource "aws_cognito_user_pool" "pool" {
  name = "unity-experimental-user-pool"
}

# Configurations for unity-uds-distribution Cognito app client
resource "aws_cognito_user_pool_client" "unity-uds-distribution-user-pool-client" {
  name = "unity-uds-distribution-user-pool-client"
  user_pool_id = aws_cognito_user_pool.pool.id
  generate_secret = true
  callback_urls = var.unity_uds_distribution_callback_urls
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["email", "openid"]
  explicit_auth_flows = ["ALLOW_CUSTOM_AUTH", "ALLOW_USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  supported_identity_providers = ["COGNITO"]
}

# Configurations for localhost-jupyterhub Cognito app client
resource "aws_cognito_user_pool_client" "localhost-jupyterhub-user-pool-client" {
  name = "localhost-jupyterhub-user-pool-client"
  user_pool_id = aws_cognito_user_pool.pool.id
  generate_secret = true
  callback_urls = var.localhost_jupyterhub_callback_urls
  logout_urls = var.localhost_jupyterhub_logout_urls
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["email", "openid"]
  explicit_auth_flows = ["ALLOW_CUSTOM_AUTH", "ALLOW_USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  supported_identity_providers = ["COGNITO"]
}

# Configurations for unity-app-to-app-client Cognito app client
resource "aws_cognito_user_pool_client" "unity-app-to-app-client-user-pool-client" {
  name = "unity-app-to-app-client-user-pool-client"
  user_pool_id = aws_cognito_user_pool.pool.id
  generate_secret = true
  allowed_oauth_flows_user_pool_client = true
  callback_urls = var.localhost_jupyterhub_callback_urls
  logout_urls = var.localhost_jupyterhub_logout_urls
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["email", "openid"]
  explicit_auth_flows = ["ALLOW_CUSTOM_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  supported_identity_providers = ["COGNITO"]
}

# Configurations for uads-jupyter-development Cognito app client
resource "aws_cognito_user_pool_client" "uads-jupyter-development-client-user-pool-client" {
  name = "uads-jupyter-development-client-user-pool-client"
  user_pool_id = aws_cognito_user_pool.pool.id
  callback_urls = var.uads_jupyter-development_client_callback_urls
  logout_urls = var.uads_jupyter-development_client_logout_urls
  generate_secret = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["email", "openid"]
  explicit_auth_flows = ["ALLOW_CUSTOM_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  supported_identity_providers = ["COGNITO"]
}

# Configurations for hysds-ui Cognito app client
resource "aws_cognito_user_pool_client" "hysds-ui-client-user-pool-client" {
  name = "hysds-ui-client-user-pool-client"
  user_pool_id = aws_cognito_user_pool.pool.id
  callback_urls = var.hysds_ui_client_callback_urls
  logout_urls = var.hysds_ui_client_logout_urls
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["email", "openid"]
  explicit_auth_flows = ["ALLOW_CUSTOM_AUTH", "ALLOW_USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  supported_identity_providers = ["COGNITO"]
}

# Configurations for localhost-hysds-ui Cognito app client
resource "aws_cognito_user_pool_client" "localhost-hysds-ui-client-user-pool-client" {
  name = "localhost-hysds-ui-client-user-pool-client"
  user_pool_id = aws_cognito_user_pool.pool.id
  callback_urls = var.localhost_hysds_ui_client_callback_urls
  logout_urls = var.localhost_hysds_ui_client_logout_urls
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["email", "openid"]
  explicit_auth_flows = ["ALLOW_CUSTOM_AUTH", "ALLOW_USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  supported_identity_providers = ["COGNITO"]
}

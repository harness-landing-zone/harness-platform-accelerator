resource "harness_platform_connector_vault" "vault" {
  count = var.connector_type == "vault" ? 1 : 0

  identifier  = var.connector_identifier
  name        = var.connector_name
  org_id      = var.org_id
  project_id  = var.project_id
  description = var.connector_description
  tags        = var.connector_tags

  vault_url                = var.vault_url
  renewal_interval_minutes = var.renewal_interval_minutes
  base_path                = var.base_path
  namespace                = var.namespace
  secret_engine_name       = var.secret_engine_name
  secret_engine_version    = var.secret_engine_version
  is_default               = var.is_default
  is_read_only             = var.is_read_only
  delegate_selectors       = var.delegate_selectors
  execute_on_delegate      = var.execute_on_delegate

  # Auth mode: OIDC (Vault JWT/OIDC auth method). auth_token is a secret
  # reference (e.g. account.harness_token) holding the JWT Harness presents.
  use_jwt_auth        = var.jwt_authentication != null
  auth_token          = try(var.jwt_authentication.auth_token, null)
  vault_jwt_auth_path = try(var.jwt_authentication.vault_jwt_auth_path, null)
  vault_jwt_auth_role = try(var.jwt_authentication.vault_jwt_auth_role, null)
}

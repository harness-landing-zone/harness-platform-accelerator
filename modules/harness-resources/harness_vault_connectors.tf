# Secret manager connectors (HashiCorp Vault, ...) — scoped account / org / project.
# OIDC auth maps to Vault's JWT/OIDC auth method: use_jwt_auth + role/path, with the
# JWT supplied via auth_token (a Harness secret reference, never an inline value).

locals {
  secret_manager_connectors = try(local.merged_sources["secret-manager-connectors"], {})
}

resource "harness_platform_connector_vault" "vault" {
  for_each = {
    for c in local.secret_manager_connectors : c.identifier => c
    if lower(lookup(c.cnf, "type", "")) == "vault"
  }

  identifier  = each.value.identifier
  name        = each.value.name
  org_id      = local.resolved_org_id
  project_id  = local.resolved_project_id
  description = lookup(each.value.cnf, "description", "Vault connector managed by Solutions Factory")
  tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])

  vault_url                = each.value.cnf.vault_url
  renewal_interval_minutes = try(each.value.cnf.renewal_interval_minutes, 10)
  base_path                = try(each.value.cnf.base_path, null)
  namespace                = try(each.value.cnf.namespace, null)
  secret_engine_name       = try(each.value.cnf.secret_engine_name, null)
  secret_engine_version    = try(each.value.cnf.secret_engine_version, null)
  is_default               = try(each.value.cnf.is_default, false)
  is_read_only             = try(each.value.cnf.is_read_only, false)
  delegate_selectors       = try(each.value.cnf.delegate_selectors, null)
  execute_on_delegate      = try(each.value.cnf.execute_on_delegate, null)

  # Auth mode: OIDC (Vault JWT/OIDC auth method). auth_token is a secret reference
  # (e.g. account.harness_token) holding the JWT Harness presents to Vault.
  use_jwt_auth        = try(each.value.cnf.use_jwt_auth, true)
  vault_jwt_auth_path = try(each.value.cnf.vault_jwt_auth_path, null)
  vault_jwt_auth_role = try(each.value.cnf.vault_jwt_auth_role, null)
  auth_token          = try(each.value.cnf.auth_token, null)
}

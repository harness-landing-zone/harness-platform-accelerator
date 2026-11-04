# Secret manager connectors (HashiCorp Vault, ...) — scoped account / org / project.
# OIDC auth maps to Vault's JWT/OIDC auth method; the JWT is supplied via a
# Harness secret reference (auth_token), never an inline value.

locals {
  secret_provider_connectors = local.merged_sources["secret-manager-connectors"]
}

module "secret_provider_connector" {
  source = "../secret-manager-connectors"
  for_each = {
    for connector in local.secret_provider_connectors : connector.identifier => connector
    if lower(lookup(connector.cnf, "type", "")) == "vault"
  }

  connector_type = "vault"

  org_id     = local.resolved_org_id
  project_id = local.resolved_project_id

  connector_name        = each.value.name
  connector_identifier  = each.value.identifier
  connector_description = lookup(each.value.cnf, "description", "Vault connector managed by Solutions Factory")
  connector_tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])

  execute_on_delegate = try(each.value.cnf.execute_on_delegate, false)

  vault_url                = each.value.cnf.vault_url
  renewal_interval_minutes = try(each.value.cnf.renewal_interval_minutes, 10)
  base_path                = try(each.value.cnf.base_path, null)
  namespace                = try(each.value.cnf.namespace, null)
  secret_engine_name       = try(each.value.cnf.secret_engine_name, null)
  secret_engine_version    = try(each.value.cnf.secret_engine_version, null)
  is_default               = try(each.value.cnf.is_default, false)
  is_read_only             = try(each.value.cnf.is_read_only, false)
  delegate_selectors       = try(each.value.cnf.delegate_selectors, null)

  jwt_authentication = {
    auth_token          = each.value.cnf.auth_token
    vault_jwt_auth_path = try(each.value.cnf.vault_jwt_auth_path, null)
    vault_jwt_auth_role = try(each.value.cnf.vault_jwt_auth_role, null)
  }
}

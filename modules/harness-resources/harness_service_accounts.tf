# Service accounts provide machine/automation access to Harness APIs
# Can be created at account, organization, or project scope
# Each service account can have API keys and tokens for authentication

locals {
  service_accounts_configs = try(local.merged_sources["service-accounts"], {})
}

##############################################################################
# Service Accounts
# Machine users for automation, CI/CD integration, and API access
##############################################################################

resource "harness_platform_service_account" "service_accounts" {
  for_each = local.service_accounts_configs

  identifier = each.value.identifier
  name       = each.value.name
  org_id     = local.resolved_org_id
  project_id = local.resolved_project_id

  email = lookup(each.value.cnf, "email", "${each.value.identifier}@service.harness.io")

  description = lookup(each.value.cnf, "description", "Service account managed by Solutions Factory")

  tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])
}

##############################################################################
# API Keys
# Each service account can have one or more API keys
# API keys are used to generate authentication tokens
##############################################################################

resource "harness_platform_apikey" "apikeys" {
  depends_on = [harness_platform_service_account.service_accounts]

  for_each = merge([
    for sa_key, sa in local.service_accounts_configs : {
      for apikey in lookup(sa.cnf, "apikeys", []) :
      "${sa_key}_${lookup(apikey, "identifier", "default")}" => merge(apikey, {
        sa_identifier = sa.identifier
        sa_key        = sa_key
      })
    }
  ]...)

  identifier  = lookup(each.value, "identifier", "${each.value.sa_identifier}_apikey")
  name        = lookup(each.value, "name", "${harness_platform_service_account.service_accounts[each.value.sa_key].name} API Key")
  parent_id   = harness_platform_service_account.service_accounts[each.value.sa_key].identifier
  apikey_type = "SERVICE_ACCOUNT"
  account_id  = local.scope == "account" ? var.harness_platform_account : null
  org_id      = local.resolved_org_id
  project_id  = local.resolved_project_id

  description = lookup(each.value, "description", "API Key for ${harness_platform_service_account.service_accounts[each.value.sa_key].name}")

  tags = flatten([
    [for k, v in lookup(each.value, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])

  lifecycle {
    ignore_changes = [default_time_to_expire_token]
  }
}

##############################################################################
# Tokens
# Authentication tokens generated from API keys
# The token value is stored and can be used for authentication
##############################################################################

resource "harness_platform_token" "tokens" {
  depends_on = [harness_platform_apikey.apikeys]

  for_each = merge([
    for sa_key, sa in local.service_accounts_configs : {
      for apikey in lookup(sa.cnf, "apikeys", []) :
      "${sa_key}_${lookup(apikey, "identifier", "default")}" => merge(apikey, {
        sa_identifier     = sa.identifier
        sa_key            = sa_key
        apikey_identifier = lookup(apikey, "identifier", "${sa.identifier}_apikey")
      })
      if lookup(apikey, "create_token", true) == true
    }
  ]...)

  identifier  = lookup(each.value, "token_identifier", "${each.value.sa_identifier}_token")
  name        = lookup(each.value, "token_name", "${each.value.sa_identifier} Token")
  parent_id   = harness_platform_service_account.service_accounts[each.value.sa_key].identifier
  apikey_type = "SERVICE_ACCOUNT"
  apikey_id   = harness_platform_apikey.apikeys["${each.value.sa_key}_${lookup(each.value, "identifier", "default")}"].identifier
  account_id  = local.scope == "account" ? var.harness_platform_account : null
  org_id      = local.resolved_org_id
  project_id  = local.resolved_project_id

  valid_from = lookup(each.value, "valid_from", null)
  valid_to   = lookup(each.value, "valid_to", null)

  lifecycle {
    # Token values are sensitive and should not be shown in output
    ignore_changes = [valid_from]
  }
}

##############################################################################
# Role Assignments for Service Accounts
# Assign roles to service accounts for authorization
##############################################################################

resource "harness_platform_role_assignments" "service_account_roles" {
  depends_on = [harness_platform_service_account.service_accounts]

  for_each = merge([
    for sa_key, sa in local.service_accounts_configs : {
      for idx, role_assignment in lookup(sa.cnf, "role_assignments", []) :
      "${sa_key}_${idx}" => merge(role_assignment, {
        sa_identifier = sa.identifier
        sa_key        = sa_key
      })
    }
  ]...)

  resource_group_identifier = each.value.resource_group_identifier
  role_identifier           = each.value.role_identifier
  org_id                    = local.resolved_org_id
  project_id                = local.resolved_project_id

  principal {
    identifier = harness_platform_service_account.service_accounts[each.value.sa_key].id
    type       = "SERVICE_ACCOUNT"
  }

  managed = lookup(each.value, "managed", false)

  disabled = lookup(each.value, "disabled", false)
}

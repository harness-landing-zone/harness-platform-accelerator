# Account-level service account for the platform-deploy pipeline.
# Scoped at account level so it can manage orgs and projects across the platform.

locals {
  # Identifier-safe slug for the org that owns this deployer.
  deployer_org = lower(replace(trimspace(var.organization_name), "/[^a-zA-Z0-9]+/", "_"))

  # Logical base shared by the service account and its credentials.
  deployer_base = "${local.deployer_org}_platform_deployer"

  # Human-readable display base, e.g. "HPA Platform Deployer".
  deployer_display = "${upper(local.deployer_org)} Platform Deployer"

  # Single source of truth for the token-secret identifier. Pipelines reference
  # it via <+secrets.getValue("...")>; also surfaced in outputs.tf.
  deployer_secret_id = "${local.deployer_base}_token"
}

resource "harness_platform_service_account" "harness_bootstrap" {
  identifier  = local.deployer_base
  name        = local.deployer_display
  email       = "${local.deployer_base}@service.harness.io"
  account_id  = var.harness_platform_account
  description = "Service account that deploys platform resources (orgs, projects, RBAC, connectors) for the ${var.organization_name} organization."
}

resource "harness_platform_apikey" "harness_bootstrap" {
  depends_on = [harness_platform_service_account.harness_bootstrap]

  identifier  = "${local.deployer_base}_apikey"
  name        = "${local.deployer_display} API Key"
  parent_id   = harness_platform_service_account.harness_bootstrap.identifier
  apikey_type = "SERVICE_ACCOUNT"
  account_id  = var.harness_platform_account

  lifecycle {
    ignore_changes = [default_time_to_expire_token]
  }
}

resource "harness_platform_token" "harness_bootstrap" {
  depends_on = [harness_platform_apikey.harness_bootstrap]

  identifier  = "${local.deployer_base}_token"
  name        = "${local.deployer_display} Token"
  parent_id   = harness_platform_service_account.harness_bootstrap.identifier
  apikey_type = "SERVICE_ACCOUNT"
  apikey_id   = harness_platform_apikey.harness_bootstrap.identifier
  account_id  = var.harness_platform_account
}

# Org/project-scoped secret storing the SA token value.
# Referenced in pipelines as: <+secrets.getValue("<org>_platform_deployer_token")>
resource "harness_platform_secret_text" "harness_bootstrap" {
  depends_on = [harness_platform_token.harness_bootstrap, module.projects]

  identifier                = local.deployer_secret_id
  name                      = "${local.deployer_display} Token"
  description               = "Auto-generated token for the ${local.deployer_display} service account"
  org_id                    = module.platform_management.organization_id
  project_id                = "platform_management"
  secret_manager_identifier = "harnessSecretManager"

  value_type = "Inline"
  value      = harness_platform_token.harness_bootstrap.value
}

resource "harness_platform_role_assignments" "harness_bootstrap_account_admin" {
  depends_on = [harness_platform_service_account.harness_bootstrap]

  resource_group_identifier = "_all_resources_including_child_scopes"
  role_identifier           = "_account_admin"

  principal {
    identifier = harness_platform_service_account.harness_bootstrap.id
    type       = "SERVICE_ACCOUNT"
  }

  managed = false
}

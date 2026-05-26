# Account-level service account for the Harness Bootstrap pipeline.
# Scoped at account level so it can manage orgs and projects across the platform.

resource "harness_platform_service_account" "harness_bootstrap" {
  identifier  = "${var.prefix}harness_bootstrap"
  name        = "${var.prefix} Harness Bootstrap"
  email       = "${var.prefix}harness-bootstrap@service.harness.io"
  account_id  = var.harness_platform_account
  description = "Service account for the Harness Bootstrap pipeline — manages orgs, projects, and resources via the tofu_deploy pipeline"
}

resource "harness_platform_apikey" "harness_bootstrap" {
  depends_on = [harness_platform_service_account.harness_bootstrap]

  identifier  = "${var.prefix}harness_bootstrap_apikey"
  name        = "${var.prefix} Harness Bootstrap API Key"
  parent_id   = harness_platform_service_account.harness_bootstrap.identifier
  apikey_type = "SERVICE_ACCOUNT"
  account_id  = var.harness_platform_account

  lifecycle {
    ignore_changes = [default_time_to_expire_token]
  }
}

resource "harness_platform_token" "harness_bootstrap" {
  depends_on = [harness_platform_apikey.harness_bootstrap]

  identifier  = "${var.prefix}harness_bootstrap_token"
  name        = "${var.prefix} Harness Bootstrap Token"
  parent_id   = harness_platform_service_account.harness_bootstrap.identifier
  apikey_type = "SERVICE_ACCOUNT"
  apikey_id   = harness_platform_apikey.harness_bootstrap.identifier
  account_id  = var.harness_platform_account
}

# Account-level secret storing the SA token value.
# Referenced in pipelines as: <+secrets.getValue("account.harness_bootstrap_api_key")>
resource "harness_platform_secret_text" "harness_bootstrap" {
  depends_on = [harness_platform_token.harness_bootstrap, module.projects]

  identifier                = "${var.prefix}harness_bootstrap_api_key"
  name                      = "${var.prefix} Harness Bootstrap API Key"
  description               = "Auto-generated token for the Harness Bootstrap service account"
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

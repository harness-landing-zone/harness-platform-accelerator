# Dedicated account identity for the developer-facing project request Workflow.
# Keep this separate from the account-admin platform deployer above.

locals {
  idp_runner_id         = "idp_project_request_runner"
  idp_runner_name       = "IDP Project Request Runner"
  idp_runner_secret_id  = "idp_project_request_runner_token"
  idp_runner_role_id    = "idp_project_request_runner"
  idp_runner_org_id     = module.platform_management.organization_id
  idp_runner_project_id = module.projects["platform_management"].project_identifier
}

resource "harness_platform_service_account" "idp_project_request_runner" {
  identifier  = local.idp_runner_id
  name        = local.idp_runner_name
  email       = "${local.idp_runner_id}@service.harness.io"
  account_id  = var.harness_platform_account
  description = "Executes only the fixed backend resources used by the IDP project request Workflow."
}

resource "harness_platform_apikey" "idp_project_request_runner" {
  identifier  = "${local.idp_runner_id}_apikey"
  name        = "${local.idp_runner_name} API Key"
  parent_id   = harness_platform_service_account.idp_project_request_runner.identifier
  apikey_type = "SERVICE_ACCOUNT"
  account_id  = var.harness_platform_account

  lifecycle {
    ignore_changes = [default_time_to_expire_token]
  }
}

resource "harness_platform_token" "idp_project_request_runner" {
  identifier  = "${local.idp_runner_id}_token"
  name        = "${local.idp_runner_name} Token"
  parent_id   = harness_platform_service_account.idp_project_request_runner.identifier
  apikey_type = "SERVICE_ACCOUNT"
  apikey_id   = harness_platform_apikey.idp_project_request_runner.identifier
  account_id  = var.harness_platform_account
}

# IDP resolves apiKeySecret only from account scope.
resource "harness_platform_secret_text" "idp_project_request_runner" {
  identifier                = local.idp_runner_secret_id
  name                      = "${local.idp_runner_name} Token"
  description               = "Generated API token for the IDP project request Workflow runner."
  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = harness_platform_token.idp_project_request_runner.value
}

resource "harness_platform_roles" "idp_project_request_runner" {
  identifier  = local.idp_runner_role_id
  name        = local.idp_runner_name
  description = "Runs the IDP project-request pipelines with access only to their runtime dependencies."

  allowed_scope_levels = ["account", "organization", "project"]
  permissions = [
    "core_connector_access",
    "core_connector_view",
    "core_pipeline_execute",
    "core_pipeline_view",
    "core_secret_access",
    "core_secret_view",
    "iac_workspace_edit",
    "iac_workspace_view",
  ]
}

resource "harness_platform_resource_group" "idp_runner_account_connector" {
  identifier           = "idp_runner_account_connector"
  name                 = "IDP Runner Account Connector"
  description          = "The account connector required by the IDP project-request pipelines."
  account_id           = var.harness_platform_account
  allowed_scope_levels = ["account"]

  included_scopes {
    filter     = "EXCLUDING_CHILD_SCOPES"
    account_id = var.harness_platform_account
  }

  resource_filter {
    include_all_resources = false
    resources {
      resource_type = "CONNECTOR"
      identifiers   = ["harnessImage"]
    }
  }
}

resource "harness_platform_resource_group" "idp_runner_org_connector" {
  depends_on = [module.platform_management]

  identifier           = "idp_runner_org_connector"
  name                 = "IDP Runner Platform Config Connector"
  description          = "The organization connector required by the IDP project-request pipelines."
  account_id           = var.harness_platform_account
  org_id               = local.idp_runner_org_id
  allowed_scope_levels = ["organization"]

  included_scopes {
    filter     = "EXCLUDING_CHILD_SCOPES"
    account_id = var.harness_platform_account
    org_id     = local.idp_runner_org_id
  }

  resource_filter {
    include_all_resources = false
    resources {
      resource_type = "CONNECTOR"
      identifiers   = ["platform_configs"]
    }
  }
}

resource "harness_platform_resource_group" "idp_runner_project_backend" {
  depends_on = [module.projects, harness_platform_secret_text.harness_bootstrap]

  identifier           = "idp_runner_project_backend"
  name                 = "IDP Project Request Backend"
  description          = "The fixed pipelines, secret, and landing-zone workspaces used by the IDP project request Workflow."
  account_id           = var.harness_platform_account
  org_id               = local.idp_runner_org_id
  project_id           = local.idp_runner_project_id
  allowed_scope_levels = ["project"]

  included_scopes {
    filter     = "EXCLUDING_CHILD_SCOPES"
    account_id = var.harness_platform_account
    org_id     = local.idp_runner_org_id
    project_id = local.idp_runner_project_id
  }

  resource_filter {
    include_all_resources = false
    resources {
      resource_type = "PIPELINE"
      identifiers   = ["idp_request_project", "tofu_deploy_iacm_idp_test"]
    }
    resources {
      resource_type = "SECRET"
      identifiers   = [local.deployer_secret_id]
    }
    resources {
      resource_type = "IAC_WORKSPACE"
      attribute_filter {
        attribute_name   = "tags"
        attribute_values = ["scope:project"]
      }
    }
  }
}

resource "harness_platform_role_assignments" "idp_runner_account_connector" {
  identifier                = "idp_runner_account_connector"
  resource_group_identifier = harness_platform_resource_group.idp_runner_account_connector.identifier
  role_identifier           = harness_platform_roles.idp_project_request_runner.identifier

  principal {
    identifier  = harness_platform_service_account.idp_project_request_runner.id
    scope_level = "account"
    type        = "SERVICE_ACCOUNT"
  }

  managed = false
}

resource "harness_platform_role_assignments" "idp_runner_org_connector" {
  identifier                = "idp_runner_org_connector"
  org_id                    = local.idp_runner_org_id
  resource_group_identifier = harness_platform_resource_group.idp_runner_org_connector.identifier
  role_identifier           = harness_platform_roles.idp_project_request_runner.identifier

  role_reference {
    identifier  = harness_platform_roles.idp_project_request_runner.identifier
    scope_level = "account"
  }

  principal {
    identifier  = harness_platform_service_account.idp_project_request_runner.id
    scope_level = "account"
    type        = "SERVICE_ACCOUNT"
  }

  managed = false
}

resource "harness_platform_role_assignments" "idp_runner_project_backend" {
  identifier                = "idp_runner_project_backend"
  org_id                    = local.idp_runner_org_id
  project_id                = local.idp_runner_project_id
  resource_group_identifier = harness_platform_resource_group.idp_runner_project_backend.identifier
  role_identifier           = harness_platform_roles.idp_project_request_runner.identifier

  role_reference {
    identifier  = harness_platform_roles.idp_project_request_runner.identifier
    scope_level = "account"
  }

  principal {
    identifier  = harness_platform_service_account.idp_project_request_runner.id
    scope_level = "account"
    type        = "SERVICE_ACCOUNT"
  }

  managed = false
}

output "idp_project_request_runner_service_account" {
  description = "Identifier of the dedicated IDP project-request service account."
  value       = harness_platform_service_account.idp_project_request_runner.identifier
}

output "idp_project_request_runner_token_secret" {
  description = "Account secret referenced by the IDP Workflow apiKeySecret field."
  value       = harness_platform_secret_text.idp_project_request_runner.identifier
}

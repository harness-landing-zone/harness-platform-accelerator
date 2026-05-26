##############################################################################
# IACM Workspace — import-or-create (always converges)
#
# Uses the harness_platform_workspaces data source to check existence.
# If the workspace exists, the pipeline step imports it into the ephemeral
# state before applying — so variable changes are always reconciled.
# If it doesn't exist, apply creates it.
#
# Naming convention:
#   account  → identifier: account_setup                    name: Account Setup
#   org      → identifier: <org_identifier>                 name: <organization_name>
#   project  → identifier: <org_identifier>_<project_id>    name: <org_name> / <project_name>
##############################################################################

locals {
  ws_org_id     = "harness_platform_accelerator"
  ws_project_id = "platform_management"

  project_identifier = (
    var.project_id != null ? var.project_id :
    var.project_name != null ? replace(replace(lower(var.project_name), " ", "_"), "-", "_") :
    ""
  )

  workspace_identifier = (
    var.scope_level == "account" ? "account_setup" :
    var.scope_level == "project" ? "${lower(local.org_identifier)}_${lower(local.project_identifier)}" :
    lower(local.org_identifier)
  )

  workspace_name = (
    var.scope_level == "account" ? "Account Setup" :
    var.scope_level == "project" ? "${var.organization_name}/${var.project_name}" :
    var.organization_name
  )

  workspace_description = (
    var.scope_level == "account"
    ? "Landing Zone workspace — account-level platform resources"
    : var.scope_level == "project"
    ? "Landing Zone workspace — project ${var.project_name} in org ${var.organization_name}"
    : "Landing Zone workspace — organization ${var.organization_name}"
  )

  # Import address for terraform import: org_id/project_id/workspace_id
  workspace_import_id = "${local.ws_org_id}/${local.ws_project_id}/${local.workspace_identifier}"

  # Scope-gated variable groups. Omitted groups are not sent to the workspace,
  # so the downstream harness-platform-deployment falls back to its defaults
  # and its scope_level-gated modules stay inert.
  base_tf_vars = [
    {
      key        = "harness_platform_account"
      value      = var.harness_platform_account
      value_type = "string"
    },
    {
      key        = "harness_platform_url"
      value      = var.harness_platform_url
      value_type = "string"
    },
    {
      key        = "scope_level"
      value      = var.scope_level
      value_type = "string"
    },
    {
      key        = "configs_relative_path"
      value      = var.configs_relative_path
      value_type = "string"
    },
    {
      key        = "platform_configs_repo_name"
      value      = try(var.platform_configs_repo_name, "local-repo")
      value_type = "string"
    },
  ]

  org_tf_vars = var.scope_level == "account" ? [] : [
    {
      key        = "organization_name"
      value      = var.organization_name != null ? var.organization_name : ""
      value_type = "string"
    },
    {
      key        = "organization_id"
      value      = local.org_identifier
      value_type = "string"
    },
    {
      key        = "organization_description"
      value      = var.organization_description
      value_type = "string"
    },
  ]

  project_tf_vars = var.scope_level != "project" ? [] : [
    {
      key        = "project_name"
      value      = var.project_name != null ? var.project_name : ""
      value_type = "string"
    },
    {
      key        = "project_id"
      value      = local.project_identifier
      value_type = "string"
    },
    {
      key        = "project_key"
      value      = var.project_key != null ? var.project_key : ""
      value_type = "string"
    },
    {
      key        = "project_description"
      value      = var.project_description
      value_type = "string"
    },
  ]
}

# ── Workspace resource (always present — no count gate) ─────────────────────
module "hpa_workspace" {
  source = "../modules/iacm-workspaces"

  workspace_name        = local.workspace_name
  workspace_identifier  = local.workspace_identifier
  workspace_description = local.workspace_description
  workspace_tags = [
    "scope:${var.scope_level}",
    "managed-by:landing-zone",
  ]

  org_id     = local.ws_org_id
  project_id = local.ws_project_id

  cost_estimation_enabled = false
  provisioner_type        = "opentofu"
  provisioner_version     = var.workspace_provisioner_version

  repository           = var.workspace_repository
  repository_connector = var.workspace_repository_connector
  repository_path      = var.workspace_repository_path
  repository_branch    = var.workspace_repository_branch

  terraform_variables = concat(local.base_tf_vars, local.org_tf_vars, local.project_tf_vars)

  environment_variables = [
    {
      key        = "HARNESS_PLATFORM_API_KEY"
      value      = "hpa_harness_bootstrap_api_key"
      value_type = "secret"
    },
    {
      key        = "HARNESS_ENDPOINT"
      value      = var.harness_platform_url
      value_type = "string"
    },
    {
      key        = "HARNESS_ACCOUNT_ID"
      value      = var.harness_platform_account
      value_type = "string"
    },
  ]
}


output "workspace_identifier" {
  description = "IACM workspace identifier — always deterministic from inputs"
  value       = local.workspace_identifier
}

output "workspace_name" {
  value = local.workspace_name
}

output "workspace_exists" {
  description = "Whether the workspace already existed before this run"
  value       = local.workspace_exists
}

output "workspace_import_id" {
  description = "Import ID for existing workspaces: org_id/project_id/workspace_id"
  value       = local.workspace_import_id
}
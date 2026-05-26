locals {
  org_identifier = coalesce(
    var.organization_id,
    replace(replace(coalesce(var.organization_name, ""), " ", "_"), "-", "_")
  )
}

##############################################################################
# Account scope
# Deploys account-level resources (groups, roles, resource groups, policies,
# connectors) when create_account = true.
# Templates come from account-config/ in this folder.
##############################################################################

module "account" {
  count  = var.scope_level == "account" ? 1 : 0
  source = "../modules/harness-resources"

  harness_platform_account   = var.harness_platform_account
  harness_platform_url       = var.harness_platform_url
  tags                       = var.tags
  configs_root               = local.configs_root
  templates_root             = local.templates_root
  default_account_template   = "account-config"
  git_connector_credentials  = var.git_connector_credentials
  platform_configs_repo_name = var.platform_configs_repo_name
}

##############################################################################
# Organization scope
# Creates the org and deploys all org-level resources when
# scope_level = "organization".
# Templates come from org-default-config/ in this folder.
##############################################################################

module "organization" {
  count  = var.scope_level == "organization" ? 1 : 0
  source = "../modules/harness-resources"

  harness_platform_account   = var.harness_platform_account
  harness_platform_url       = var.harness_platform_url
  organization_name          = var.organization_name
  organization_id            = var.organization_id
  organization_description   = var.organization_description
  tags                       = var.tags
  configs_root               = local.configs_root
  templates_root             = local.templates_root
  git_connector_credentials  = var.git_connector_credentials
  platform_configs_repo_name = var.platform_configs_repo_name
}

##############################################################################
# Org-bootstrap projects
# One module instance per project discovered under
# platform-configs/organizations/<org>/projects/*/config.yaml.
# All resources land in the same state as the org above.
# Only active when scope_level = "organization" AND create_projects = true.
##############################################################################

module "projects" {
  for_each   = local.project_instances
  source     = "../modules/harness-resources"
  depends_on = [module.organization]

  harness_platform_account   = var.harness_platform_account
  harness_platform_url       = var.harness_platform_url
  organization_id            = one(module.organization[*].organization_id)
  project_name               = each.value.name
  project_key                = each.value.folder
  tags                       = var.tags
  configs_root               = local.configs_root
  org_root                   = "${local.configs_root}/organizations/${var.organization_name}"
  templates_root             = local.templates_root
  git_connector_credentials  = var.git_connector_credentials
  platform_configs_repo_name = var.platform_configs_repo_name
}

##############################################################################
# Single project (IDP)
# Deploys one named project into an existing org when
# scope_level = "project".
# The org must already exist in Harness (looked up by identifier).
# Templates come from project-default-config/ in this folder.
##############################################################################

data "harness_platform_organization" "existing" {
  count      = var.scope_level == "project" ? 1 : 0
  identifier = local.org_identifier
}

module "project" {
  count      = var.scope_level == "project" ? 1 : 0
  source     = "../modules/harness-resources"
  depends_on = [data.harness_platform_organization.existing]

  harness_platform_account   = var.harness_platform_account
  harness_platform_url       = var.harness_platform_url
  organization_name          = var.organization_name
  organization_id            = coalesce(var.organization_id, try(data.harness_platform_organization.existing[0].id, null), local.org_identifier)
  project_name               = var.project_name
  project_key                = var.project_key
  project_id                 = var.project_id
  project_description        = var.project_description
  tags                       = var.tags
  configs_root               = local.configs_root
  templates_root             = local.templates_root
  git_connector_credentials  = var.git_connector_credentials
  platform_configs_repo_name = var.platform_configs_repo_name
}

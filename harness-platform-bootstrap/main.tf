module "platform_management" {
  source = "../modules/harness-resources"

  organization_name        = var.organization_name
  harness_platform_account = var.harness_platform_account
  harness_platform_url     = var.harness_platform_url
  tags                     = var.tags

  configs_root              = local.configs_root
  templates_root            = local.templates_root
  git_connector_credentials = var.git_connector_credentials
  pem_path                  = "${path.module}/pem-folder"
}

module "projects" {
  for_each   = local.project_instances
  source     = "../modules/harness-resources"
  depends_on = [module.platform_management]

  harness_platform_account  = var.harness_platform_account
  harness_platform_url      = var.harness_platform_url
  organization_id           = module.platform_management.organization_id
  project_name              = each.value.name
  project_key               = each.value.folder
  tags                      = var.tags
  configs_root              = local.configs_root
  org_root                  = "${local.configs_root}/organizations/${var.organization_name}"
  templates_root            = local.templates_root
  git_connector_credentials = var.git_connector_credentials
}

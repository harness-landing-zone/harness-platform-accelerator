# IACM workspaces are project-scope only.

locals {
  workspaces = try(local.merged_sources["workspaces"], {})
}

module "iacm_workspace" {
  source = "../iacm-workspaces"
  depends_on = [
    data.harness_platform_project.selected,
    module.git_connector,
    module.aws_cloud_provider_connector,
  ]

  for_each = local.scope == "project" ? {
    for ws in local.workspaces : ws.identifier => ws
  } : {}

  org_id     = local.resolved_org_id
  project_id = local.resolved_project_id

  workspace_name        = each.value.name
  workspace_identifier  = each.value.identifier
  workspace_description = lookup(each.value.cnf, "description", "Harness IaCM Workspace managed by Solutions Factory")
  workspace_tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])

  cost_estimation_enabled = try(each.value.cnf.cost_estimation_enabled, false)
  provisioner_type        = each.value.cnf.provisioner_type
  provisioner_version     = each.value.cnf.provisioner_version

  repository           = each.value.cnf.repository
  repository_connector = each.value.cnf.repository_connector
  repository_path      = each.value.cnf.repository_path
  repository_branch    = try(each.value.cnf.repository_branch, null)
  repository_commit    = try(each.value.cnf.repository_commit, null)
  repository_sha       = try(each.value.cnf.repository_sha, null)

  provider_connector       = try(each.value.cnf.provider_connector, null)
  workspace_connectors     = try(each.value.cnf.workspace_connectors, [])
  terraform_variables      = try(each.value.cnf.terraform_variables, [])
  environment_variables    = try(each.value.cnf.environment_variables, [])
  terraform_variable_files = try(each.value.cnf.terraform_variable_files, [])
  variable_sets            = try(each.value.cnf.variable_sets, [])
  default_pipelines        = try(each.value.cnf.default_pipelines, {})
}

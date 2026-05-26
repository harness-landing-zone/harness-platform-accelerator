# Lookup existing workspaces to determine if creation is necessary

data "harness_platform_workspaces" "existing" {
  org_id      = local.ws_org_id
  project_id  = local.ws_project_id
  search_term = local.workspace_identifier
}

locals {
  workspace_exists = contains(
    try(data.harness_platform_workspaces.existing.identifiers, []),
    local.workspace_identifier
  )
}
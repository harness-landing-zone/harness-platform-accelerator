locals {
  policies = local.merged_sources["policies"]
}

resource "harness_platform_policy" "policies" {
  lifecycle {
    ignore_changes = [
      git_commit_msg,
      git_connector_ref,
      git_path,
      git_repo,
      git_branch,
      git_base_branch,
      git_is_new_branch,
      git_import
    ]
  }
  for_each = {
    for policy in local.policies : policy.name => policy
  }

  identifier  = each.value.identifier
  name        = each.value.name
  org_id      = local.resolved_org_id
  project_id  = local.resolved_project_id
  description = lookup(each.value.cnf, "description", "Harness Policy managed by Solutions Factory")

  # Load the raw OPA rego content directly from the file.
  rego = file("${each.value.dir}/${each.value.file}")

  tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])
}

locals {
  roles = local.merged_sources["roles"]

  permission_statuses = ["ACTIVE", "EXPERIMENTAL"]

  # Valid permissions for the current scope level, sourced live from the Harness API.
  scope_permission_identifiers = sort(compact(flatten([
    for permission in data.harness_platform_permissions.current.permissions : [
      permission.identifier
    ] if contains(local.permission_statuses, permission.status) && contains(permission.allowed_scope_levels, local.scope)
  ])))

  # Per-role list of permissions that are invalid at this scope.
  invalid_scope_permissions = {
    for role in local.roles :
    (role.name) => flatten([
      for permission in try(role.cnf.permissions, []) : [
        permission
      ] if !contains(local.scope_permission_identifiers, permission)
    ])
  }
}

output "roles" {
  value = local.merged_sources["roles"]
}

resource "harness_platform_roles" "role" {
  for_each = {
    for role in local.roles : role.name => role
  }

  lifecycle {
    precondition {
      condition     = length(local.invalid_scope_permissions[each.key]) == 0
      error_message = <<EOF
      [Invalid] The following permissions are invalid for role "${each.key}" at ${local.scope} scope:
      - ${join("\n      - ", local.invalid_scope_permissions[each.key])}
      EOF
    }
  }

  identifier           = each.value.identifier
  name                 = each.value.name
  org_id               = local.resolved_org_id
  project_id           = local.resolved_project_id
  allowed_scope_levels = [local.scope]
  permissions          = try(each.value.cnf.permissions, [])
  tags                 = local.common_tags_tuple
}

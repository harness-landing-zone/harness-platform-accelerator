locals {
  all_groups = local.merged_sources["groups"]

  groups = [
    for group in local.all_groups : group
    if !startswith(group.name, "_") && !try(group.cnf.scope_level == "account", false)
  ]

  existing_groups = [
    for group in local.all_groups : group
    if startswith(group.name, "_") || try(group.cnf.scope_level == "account", false)
  ]

  groups_bindings = flatten([
    for group in local.all_groups : [
      for binding in try(group.cnf.role_bindings, []) : {
        identifier       = "${group.identifier}_${lookup(binding, "role", "MISSING-ROLE-ID")}"
        group_identifier = group.identifier
        group_name       = group.name
        scope_level      = try(group.cnf.scope_level, null)
        role             = lookup(binding, "role", "MISSING-ROLE")
        resource_group   = lookup(binding, "resource_group", "MISSING-ROLE")
      }
    ]
  ])
}

data "harness_platform_usergroup" "usergroup" {
  for_each = {
    for group in local.existing_groups : group.identifier => group
  }
  identifier = each.value.identifier
  org_id     = try(each.value.cnf.scope_level == "account" ? null : local.resolved_org_id, local.resolved_org_id)
  project_id = try(each.value.cnf.scope_level == "account" ? null : local.resolved_project_id, local.resolved_project_id)
}

resource "harness_platform_usergroup" "usergroup" {
  depends_on = [harness_platform_roles.role, harness_platform_resource_group.resource_group]
  lifecycle {
    ignore_changes = [
      users,
      user_emails,
      linked_sso_id,
      linked_sso_display_name,
      linked_sso_type,
      notification_configs,
      sso_linked,
      sso_group_id,
      sso_group_name
    ]
  }
  for_each = {
    for group in local.groups : group.identifier => group
  }

  identifier  = each.value.identifier
  name        = each.value.name
  org_id      = local.resolved_org_id
  project_id  = local.resolved_project_id
  description = lookup(each.value.cnf, "description", "Harness UserGroup managed by Solutions Factory")
  user_emails = []

  externally_managed      = false
  linked_sso_id           = lookup(each.value.cnf, "linked_sso_id", null)
  linked_sso_display_name = lookup(each.value.cnf, "linked_sso_display_name", null)
  linked_sso_type         = lookup(each.value.cnf, "linked_sso_type", null)
  sso_linked              = lookup(each.value.cnf, "sso_group_id", null) != null ? true : false
  sso_group_id            = lookup(each.value.cnf, "sso_group_id", null)
  sso_group_name          = lookup(each.value.cnf, "sso_group_name", null)

  tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])
}

resource "harness_platform_role_assignments" "usergroup_bindings" {
  depends_on = [harness_platform_usergroup.usergroup]
  for_each = {
    for group in local.groups_bindings : group.identifier => group
  }

  identifier                = each.value.identifier
  org_id                    = local.resolved_org_id
  project_id                = local.resolved_project_id
  resource_group_identifier = each.value.resource_group
  role_identifier           = each.value.role
  principal {
    scope_level = try(each.value.scope_level, null)
    identifier = try(
      harness_platform_usergroup.usergroup[each.value.group_identifier].id,
      harness_platform_usergroup.usergroup[each.value.group_name].id,
      data.harness_platform_usergroup.usergroup[each.value.group_identifier].id
    )
    type = "USER_GROUP"
  }
  disabled = false
  managed  = false
}

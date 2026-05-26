locals {
  resource_groups = local.merged_sources["resource_groups"]
}

resource "harness_platform_resource_group" "resource_group" {
  for_each = {
    for resource_group in local.resource_groups : resource_group.name => resource_group
  }

  identifier  = each.value.identifier
  name        = each.value.name
  description = lookup(each.value.cnf, "description", "Harness ResourceGroup managed by Solutions Factory")
  account_id  = var.harness_platform_account
  org_id      = local.resolved_org_id
  project_id  = local.resolved_project_id

  tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])

  # allowed_scope_levels and included_scopes reflect the deployment scope so
  # account resource groups are account-scoped, org ones are org-scoped, etc.
  allowed_scope_levels = [local.scope]

  included_scopes {
    filter     = lookup(each.value.cnf, "include_child_scopes", false) ? "INCLUDING_CHILD_SCOPES" : "EXCLUDING_CHILD_SCOPES"
    account_id = var.harness_platform_account
    org_id     = local.resolved_org_id
    project_id = local.resolved_project_id
  }

  resource_filter {
    include_all_resources = lookup(each.value.cnf, "resource_filters", null) != null ? false : true
    dynamic "resources" {
      for_each = lookup(each.value.cnf, "resource_filters", [])
      content {
        resource_type = lookup(resources.value, "type", null)
        identifiers   = lookup(resources.value, "identifiers", null)
        dynamic "attribute_filter" {
          for_each = lookup(resources.value, "filters", [])
          content {
            attribute_name   = lookup(attribute_filter.value, "name", null)
            attribute_values = flatten([lookup(attribute_filter.value, "values", [])])
          }
        }
      }
    }
  }
}

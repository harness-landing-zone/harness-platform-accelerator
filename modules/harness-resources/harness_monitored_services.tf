# Monitored services (SRM) with their health sources — project-scope only.

locals {
  monitored_services = try(local.merged_sources["monitored_services"], {})
}

resource "harness_platform_monitored_service" "monitored_services" {
  depends_on = [
    data.harness_platform_project.selected,
    # Health sources reference connectors by connectorRef (a plain string), so
    # the edge is not implicit — force connectors to create first.
    harness_platform_connector_prometheus.prometheus,
  ]

  for_each = local.scope == "project" ? {
    for k, m in local.monitored_services :
    coalesce(try(m.cnf.identifier, null), m.identifier) => m
  } : {}

  identifier = coalesce(try(each.value.cnf.identifier, null), each.value.identifier)
  org_id     = local.resolved_org_id
  project_id = local.resolved_project_id

  request {
    name            = each.value.name
    type            = lookup(each.value.cnf, "type", "Application")
    description     = lookup(each.value.cnf, "description", "Monitored service managed by Solutions Factory")
    service_ref     = each.value.cnf.service_ref
    environment_ref = each.value.cnf.environment_ref
    tags = flatten([
      [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
      local.common_tags_tuple
    ])

    dynamic "health_sources" {
      for_each = lookup(each.value.cnf, "health_sources", [])
      content {
        name       = health_sources.value.name
        identifier = health_sources.value.identifier
        type       = health_sources.value.type
        version    = lookup(health_sources.value, "version", null)
        # spec is a provider-side JSON string; the config carries it as a native map.
        spec = jsonencode(lookup(health_sources.value, "spec", {}))
      }
    }

    dynamic "change_sources" {
      for_each = lookup(each.value.cnf, "change_sources", [])
      content {
        name       = change_sources.value.name
        identifier = change_sources.value.identifier
        type       = change_sources.value.type
        enabled    = lookup(change_sources.value, "enabled", true)
        category   = change_sources.value.category
        spec       = jsonencode(lookup(change_sources.value, "spec", {}))
      }
    }
  }
}

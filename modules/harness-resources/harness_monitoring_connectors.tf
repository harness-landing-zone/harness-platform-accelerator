# Monitoring connectors (Prometheus, ...) — referenced by monitored-service health sources.
# Scoped like other connectors: account / organization / project.

locals {
  monitoring_connectors = try(local.merged_sources["monitoring-connectors"], {})
}

resource "harness_platform_connector_prometheus" "prometheus" {
  for_each = {
    for c in local.monitoring_connectors : c.identifier => c
    if lower(lookup(c.cnf, "type", "")) == "prometheus"
  }

  identifier  = each.value.identifier
  name        = each.value.name
  org_id      = local.resolved_org_id
  project_id  = local.resolved_project_id
  description = lookup(each.value.cnf, "description", "Prometheus connector managed by Solutions Factory")
  tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])

  url                = each.value.cnf.url
  user_name          = try(each.value.cnf.user_name, null)
  password_ref       = try(each.value.cnf.password_ref, null)
  delegate_selectors = try(each.value.cnf.delegate_selectors, null)

  dynamic "headers" {
    for_each = lookup(each.value.cnf, "headers", [])
    content {
      key                 = headers.value.key
      value               = try(headers.value.value, null)
      value_encrypted     = try(headers.value.value_encrypted, null)
      encrypted_value_ref = try(headers.value.encrypted_value_ref, null)
    }
  }
}

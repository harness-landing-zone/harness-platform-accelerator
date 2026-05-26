# Services are project-scope only.

locals {
  services = try(local.merged_sources["services"], {})
}

resource "harness_platform_service" "services" {
  for_each = local.scope == "project" ? {
    for service in local.services : service.name => service
  } : {}

  identifier  = each.value.identifier
  name        = each.value.name
  org_id      = local.resolved_org_id
  project_id  = local.resolved_project_id
  description = lookup(each.value.cnf, "description", "Harness Service managed by Solutions Factory")
  tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])

  yaml = lookup(each.value.cnf, "yaml", {}) != {} ? replace(yamlencode(each.value.cnf.yaml), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:") : ""
}

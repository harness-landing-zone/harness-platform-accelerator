locals {
  environments = local.merged_sources["environments"]

  environment_overrides = [
    for override in local.environments : override
    if lookup(override.cnf, "yaml", {}) != {}
  ]
}

resource "harness_platform_environment" "environments" {
  for_each = {
    for environment in local.environments : environment.name => environment
  }

  identifier  = each.value.identifier
  name        = each.value.name
  org_id      = local.resolved_org_id
  project_id  = local.resolved_project_id
  type        = lookup(each.value.cnf, "type", "PreProduction")
  description = lookup(each.value.cnf, "description", "Harness Environment managed by Solutions Factory")
  tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])
}

resource "harness_platform_overrides" "example" {
  for_each = {
    for environment in local.environment_overrides : environment.identifier => environment
  }
  env_id = each.value.identifier
  type   = "ENV_GLOBAL_OVERRIDE"
  yaml   = replace(yamlencode(each.value.cnf.yaml), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
}

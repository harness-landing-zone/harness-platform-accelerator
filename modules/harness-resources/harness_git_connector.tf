locals {
  git_connectors = local.merged_sources["git-connectors"]
}

module "git_connector" {
  source = "../git-connectors"
  for_each = {
    for connector in local.git_connectors : connector.identifier => connector
  }

  depends_on = [
    harness_platform_secret_text.org_secrets,
    harness_platform_secret_file.org_secrets,
  ]

  connector_type        = each.value.cnf.type
  org_id                = local.resolved_org_id
  project_id            = local.resolved_project_id
  connector_name        = each.value.cnf.name
  connector_identifier  = each.value.identifier
  connector_description = lookup(each.value.cnf, "description", "Harness Git connector managed by Solutions Factory")
  connector_tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])

  git_connector_url   = each.value.cnf.connector_url
  connection_type     = each.value.cnf.connection_type
  validation_repo     = try(each.value.cnf.validation_repo, null)
  execute_on_delegate = try(each.value.cnf.execute_on_delegate, false)
  delegate_selectors  = try(each.value.cnf.delegate_selectors, [])

  git_connector_http_credentials = try(each.value.cnf.http_credentials, try(var.git_connector_credentials[each.key].http_credentials, null))
  git_connector_ssh_credentials  = try(each.value.cnf.ssh_credentials, try(var.git_connector_credentials[each.key].ssh_credentials, null))
  git_connector_api_auth         = try(each.value.cnf.api_auth, try(var.git_connector_credentials[each.key].api_auth, null))
}

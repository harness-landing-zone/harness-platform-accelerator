locals {
  cloud_provider_connectors = local.merged_sources["cloud-provider-connectors"]
}

module "aws_cloud_provider_connector" {
  source = "../cloud-provider-connectors"
  for_each = {
    for connector in local.cloud_provider_connectors : connector.identifier => connector
    if lower(lookup(connector.cnf, "type", "")) == "aws"
  }

  org_id     = local.resolved_org_id
  project_id = local.resolved_project_id

  connector_name        = each.value.name
  connector_identifier  = each.value.identifier
  connector_description = lookup(each.value.cnf, "description", "Harness AWS connector managed by Solutions Factory")
  connector_tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])

  execute_on_delegate = try(each.value.cnf.execute_on_delegate, false)
  force_delete        = try(each.value.cnf.force_delete, false)

  aws_connector_oidc_authentication   = try(each.value.cnf.oidc_authentication, null)
  aws_connector_manual_authentication = try(each.value.cnf.manual_authentication, null)
  aws_connector_inherit_from_delegate = try(each.value.cnf.inherit_from_delegate, null)
  aws_connector_irsa_authentication   = try(each.value.cnf.irsa_authentication, null)
  aws_connector_cross_account_access  = try(each.value.cnf.cross_account_access, null)

  aws_connector_equal_jitter_backoff_strategy = try(each.value.cnf.equal_jitter_backoff_strategy, null)
  aws_connector_fixed_delay_backoff_strategy  = try(each.value.cnf.fixed_delay_backoff_strategy, null)
  aws_connector_full_jitter_backoff_strategy  = try(each.value.cnf.full_jitter_backoff_strategy, null)
}

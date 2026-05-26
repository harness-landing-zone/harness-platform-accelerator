# Secrets are org-scope only. The for_each guard produces an empty map at
# account and project scope so no resources are created.

locals {
  all_secrets = try(local.merged_sources["secrets"], {})

  secrets_text = {
    for k, s in local.all_secrets :
    k => s if lower(lookup(s.cnf, "type", "text")) == "text"
  }

  secrets_file = {
    for k, s in local.all_secrets :
    k => s if lower(lookup(s.cnf, "type", "text")) == "file"
  }
}

resource "harness_platform_secret_text" "org_secrets" {
  for_each = local.scope == "organization" ? {
    for k, s in local.secrets_text :
    coalesce(try(s.cnf.identifier, null), s.identifier) => s
  } : {}

  identifier = coalesce(try(each.value.cnf.identifier, null), each.value.identifier)
  name       = each.value.name
  org_id     = local.resolved_org_id

  description               = lookup(each.value.cnf, "description", "Secret managed by Solutions Factory")
  tags                      = local.common_tags_tuple
  secret_manager_identifier = lookup(each.value.cnf, "secret_manager_identifier", "harnessSecretManager")

  value_type = "Inline"
  value      = var.secret_values[coalesce(try(each.value.cnf.identifier, null), each.value.identifier)]
}

resource "harness_platform_secret_file" "org_secrets" {
  for_each = local.scope == "organization" ? {
    for k, s in local.secrets_file :
    coalesce(try(s.cnf.identifier, null), s.identifier) => s
  } : {}

  identifier = coalesce(try(each.value.cnf.identifier, null), each.value.identifier)
  name       = each.value.name
  org_id     = local.resolved_org_id

  description               = lookup(each.value.cnf, "description", "Secret managed by Solutions Factory")
  tags                      = local.common_tags_tuple
  secret_manager_identifier = lookup(each.value.cnf, "secret_manager_identifier", "harnessSecretManager")

  file_path = lookup(
    each.value.cnf,
    "file_path",
    "${coalesce(var.pem_path, "${path.module}/pem")}/${coalesce(try(each.value.cnf.identifier, null), each.value.identifier)}.pem"
  )

  lifecycle {
    ignore_changes = [file_path]
  }
}

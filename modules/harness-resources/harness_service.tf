# Services can be defined at any scope: account, organization, or project.

locals {
  services = try(local.merged_sources["services"], {})

  # Separate inline-defined services from git-imported services
  inline_services = {
    for k, v in local.services :
    k => v
    if lookup(v.cnf, "git_details", null) == null
  }

  git_services = {
    for k, v in local.services :
    k => v
    if lookup(v.cnf, "git_details", null) != null
  }
}

##############################################################################
# Inline Services
# Service definition provided directly in YAML via the 'yaml' field.
# Suitable for simple services or when Git sync is not required.
# Can be created at account, org, or project scope.
##############################################################################

resource "harness_platform_service" "inline_services" {
  for_each = local.inline_services

  identifier  = each.value.identifier
  name        = each.value.name
  org_id      = local.resolved_org_id
  project_id  = local.resolved_project_id
  description = lookup(each.value.cnf, "description", "Harness Service managed by Solutions Factory")

  tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])

  # Force string type for service definition
  force_delete = lookup(each.value.cnf, "force_delete", false)

  # Service definition YAML - convert HCL map to YAML string
  # The regex replacement removes quotes around keys for cleaner YAML
  yaml = lookup(each.value.cnf, "yaml", null) != null ? (
    replace(
      yamlencode(each.value.cnf.yaml),
      "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/",
      "$1$2:"
    )
  ) : null
}

##############################################################################
# Git-Imported Services
# Service definition stored in Git repository and synced via connector.
# Enables GitOps workflow and version control for service configs.
# Can be created at account, org, or project scope.
##############################################################################

resource "harness_platform_service" "git_services" {
  depends_on = [
    module.git_connector,
    module.aws_cloud_provider_connector,
    module.gcp_cloud_provider_connector
  ]

  for_each = local.git_services

  identifier  = each.value.identifier
  name        = each.value.name
  org_id      = local.resolved_org_id
  project_id  = local.resolved_project_id
  description = lookup(each.value.cnf, "description", "Harness Service managed by Solutions Factory (Git-synced)")

  tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])

  force_delete = lookup(each.value.cnf, "force_delete", false)

  # Git repository configuration
  git_details {
    store_type = lookup(each.value.cnf.git_details, "store_type", "REMOTE")

    # Connector reference (account.connector_id or org.connector_id or connector_id)
    connector_ref = lookup(each.value.cnf.git_details, "connector_ref", "")

    # Repository name (for account/org-level GitHub connectors)
    repo_name = lookup(each.value.cnf.git_details, "repo_name", null)

    # File path in repository
    file_path = lookup(each.value.cnf.git_details, "file_path", ".harness/${each.value.identifier}.yaml")

    # Branch (optional - if not set, uses connector's default branch)
    branch = lookup(each.value.cnf.git_details, "branch", null)
  }

  lifecycle {
    # Prevent drift from Git changes - service definition is source of truth in Git
    ignore_changes = [yaml]
  }
}

locals {

  ##############################################################################
  # Scope detection
  # project  — project_name is set (organization_name must also be set)
  # organization — organization_name is set, project_name is null
  # account  — both are null
  ##############################################################################

  scope = (
    var.project_name != null ? "project" :
    var.organization_name != null ? "organization" :
    "account"
  )

  ##############################################################################
  # Path resolution
  ##############################################################################

  # Absolute path to the platform-configs root.
  platform_configs_dir = (
    var.configs_root != null
    ? var.configs_root
    : abspath("${path.module}/${var.configs_relative_path}")
  )

  # Absolute path to this org's config folder
  org_directory = (
    var.org_root != null
    ? var.org_root
    : "${local.platform_configs_dir}/organizations/${var.organization_name != null ? var.organization_name : ""}"
  )

  # The project config folder key — prefer explicit var, then derive from project_name.
  effective_project_key = (
    var.project_key != null ? var.project_key :
    var.project_name != null ? replace(replace(var.project_name, " ", "_"), "-", "_") :
    ""
  )

  # Config directory for the merge override side.
  # Account: platform_configs_dir/account/  (may be absent — try() handles it)
  # Org:     org_directory/
  # Project: org_directory/projects/<project_key>/
  config_directory = (
    local.scope == "project" ? "${local.org_directory}/projects/${local.effective_project_key}" :
    local.scope == "organization" ? local.org_directory :
    "${local.platform_configs_dir}/account"
  )

  ##############################################################################
  # Config file reads
  ##############################################################################

  org_config = local.scope == "organization" ? try(
    yamldecode(file("${local.org_directory}/config.yaml")), null
  ) : null

  project_config = local.scope == "project" ? try(
    yamldecode(file("${local.org_directory}/projects/${local.effective_project_key}/config.yaml")), null
  ) : null

  ##############################################################################
  # Template selection
  # The template directory lives inside this module and provides global defaults.
  ##############################################################################

  default_org_template = try(local.org_config.default_org_template, var.default_org_template)

  default_project_template = try(
    local.project_config.default_project_template,
    local.org_config.default_project_template,
    var.default_project_template
  )

  effective_template = (
    local.scope == "project" ? local.default_project_template :
    local.scope == "organization" ? local.default_org_template :
    var.default_account_template
  )

  # Root from which template subfolders are resolved.
  # Callers can pass an absolute path via templates_root to supply their own
  # default config trees (e.g. the deployment entrypoint's own config dirs).
  effective_templates_root = coalesce(var.templates_root, path.module)

  # Global-defaults side of the merge.
  source_directory = "${local.effective_templates_root}/${local.effective_template}"

  ##############################################################################
  # Identifier resolution
  ##############################################################################

  org_identifier = lower(
    var.organization_id != null ? var.organization_id :
    try(local.org_config.identifier, null) != null ? local.org_config.identifier :
    var.organization_name != null ? replace(replace(var.organization_name, " ", "_"), "-", "_") :
    ""
  )

  org_name        = try(local.org_config.name, var.organization_name)
  org_description = try(local.org_config.description, var.organization_description)

  project_identifier = lower(
    var.project_id != null ? var.project_id :
    try(local.project_config.identifier, null) != null ? try(local.project_config.identifier, null) :
    var.project_name != null ? replace(replace(var.project_name, " ", "_"), "-", "_") :
    ""
  )

  ##############################################################################
  # Tags
  ##############################################################################

  required_tags = {
    created_by                 = "Terraform"
    template                   = local.effective_template
    platform_configs_repo_name = var.platform_configs_repo_name
  }

  common_tags       = merge(var.tags, local.required_tags)
  common_tags_tuple = [for k, v in local.common_tags : "${k}:${v}"]

  ##############################################################################
  # Resolved scope IDs
  # Input-derived identifiers — deterministic at plan time, never become
  # "known after apply" due to data-source dependency cascades. All resource
  # files use these for org_id / project_id attributes.
  #
  # The data sources (data.harness_platform_organization.selected, etc.)
  # are kept for validation and for reading additional fields (description,
  # tags) but are NOT used to set org_id / project_id on resources.
  ##############################################################################

  # For organization scope, take the id from the org RESOURCE's identifier so
  # every org-scoped resource gains an implicit dependency on the org being
  # created first. Without this, resources like harness_platform_secret_file
  # race the org and fail with "Organization [<id>] not found" on first apply.
  # The value is the config identifier (known at plan time), so referencing the
  # resource adds only an ordering edge — no "known after apply" cascade, and
  # the resolved value is identical to local.org_identifier (no diffs/replaces).
  # For project scope the org pre-exists (looked up); ordering there is handled
  # by the calling module's depends_on, so the derived string is used directly.
  resolved_org_id = (
    local.scope == "organization" ? one(harness_platform_organization.selected[*].identifier) :
    local.scope == "project" ? local.org_identifier :
    null
  )
  resolved_project_id = local.scope == "project" ? local.project_identifier : null
}

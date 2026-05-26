locals {
  # Resolved absolute path to the platform-configs root (org/project overrides).
  # Computed here so the relative path is interpreted from the deployment
  # folder rather than from inside the harness-resources module.
  configs_root = abspath("${path.module}/${var.configs_relative_path}")

  # Absolute path to this folder — passed as templates_root to the module so
  # account-config/, org-default-config/, and project-default-config/ here are
  # used as the global-defaults layer instead of the module's own copies.
  templates_root = abspath(path.module)

  ##############################################################################
  # Project discovery (org bootstrap only)
  # Finds every projects/<key>/config.yaml under the org config directory and
  # reads each config to get the display name.
  ##############################################################################

  org_project_files = (
    var.scope_level == "organization" && var.organization_name != null
    ? try(
      fileset("${local.configs_root}/organizations/${var.organization_name}/projects", "*/config.yaml"),
      toset([])
    )
    : toset([])
  )

  project_configs = {
    for f in local.org_project_files :
    dirname(f) => try(
      yamldecode(file("${local.configs_root}/organizations/${var.organization_name}/projects/${dirname(f)}/config.yaml")),
      {}
    )
  }

  # Keyed by identifier (from config.yaml) or derived from name/folder.
  # each.key = Terraform state address; each.value.folder = config path for file lookups.
  project_instances = {
    for folder, cfg in local.project_configs :
    lower(coalesce(
      try(cfg.identifier, null),
      replace(replace(coalesce(try(cfg.name, null), folder), " ", "_"), "-", "_")
      )) => {
      folder = folder
      name   = try(cfg.name, replace(replace(folder, "_", " "), "-", " "))
    }
  }
}

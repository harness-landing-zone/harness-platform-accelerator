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
  # reads each config to get the display name ignore any case sensitive differences.
  ##############################################################################

  org_dir_names = (
    var.scope_level == "organization" && var.organization_name != null
    ? toset([
      for f in try(fileset("${local.configs_root}/organizations", "**"), toset([])) :
      split("/", f)[0]
    ])
    : toset([])
  )

  # Case-insensitive match against existing org folders; fall back to the raw
  # organization_name when no folder matches (new org / no config dir yet).
  # coalesce — not try — because one([]) returns null (not an error), so try
  # would keep the null instead of falling back.
  resolved_org_name = coalesce(
    one([for d in local.org_dir_names : d if lower(d) == lower(var.organization_name)]),
    var.organization_name
  )

  org_projects_dir = "${local.configs_root}/organizations/${local.resolved_org_name}/projects"

  org_project_files = (
    var.scope_level == "organization" && var.organization_name != null
    ? try(
      fileset(local.org_projects_dir, "*/config.yaml"),
      toset([])
    )
    : toset([])
  )

  project_configs = {
    for f in local.org_project_files :
    dirname(f) => try(
      yamldecode(file("${local.org_projects_dir}/${dirname(f)}/config.yaml")),
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

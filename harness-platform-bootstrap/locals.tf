locals {
  # The bootstrap directory is its own config and templates root.
  configs_root   = abspath(path.module)
  templates_root = abspath(path.module)

  ##############################################################################
  # Project discovery
  # Auto-discovers every projects/<key>/config.yaml under the org folder so
  # new projects are picked up without touching harness_organization.tf.
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

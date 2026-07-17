locals {

  ##############################################################################
  # Category definitions
  # Each category maps to two directories: global_dir (template defaults) and
  # org_dir (scope-specific overrides). The merge favours org_dir when the same
  # relative path exists in both.
  #
  # base_categories — present at every scope level
  # org_categories  — organization scope only
  # project_categories — project scope only
  ##############################################################################

  base_categories = {
    environments = {
      global_dir = "${local.source_directory}/environments"
      org_dir    = "${local.config_directory}/environments"
      patterns   = ["*.yaml"]
      key_fn     = "path"
    }
    groups = {
      global_dir = "${local.source_directory}/groups"
      org_dir    = "${local.config_directory}/groups"
      patterns   = ["*.yaml"]
      key_fn     = "path"
    }
    resource_groups = {
      global_dir = "${local.source_directory}/resource_groups"
      org_dir    = "${local.config_directory}/resource_groups"
      patterns   = ["*.yaml"]
      key_fn     = "path"
    }
    policy_sets = {
      global_dir = "${local.source_directory}/policy_sets"
      org_dir    = "${local.config_directory}/policy_sets"
      patterns   = ["*.yaml"]
      key_fn     = "path"
    }
    roles = {
      global_dir = "${local.source_directory}/roles"
      org_dir    = "${local.config_directory}/roles"
      patterns   = ["*.yaml"]
      key_fn     = "path"
    }
    policies = {
      global_dir = "${local.source_directory}/policies"
      org_dir    = "${local.config_directory}/policies"
      patterns   = ["*.rego"]
      key_fn     = "path"
    }
    git-connectors = {
      global_dir = "${local.source_directory}/git-connectors"
      org_dir    = "${local.config_directory}/git-connectors"
      patterns   = ["*.yaml"]
      key_fn     = "path"
    }
    cloud-provider-connectors = {
      global_dir = "${local.source_directory}/cloud-provider-connectors"
      org_dir    = "${local.config_directory}/cloud-provider-connectors"
      patterns   = ["*.yaml"]
      key_fn     = "path"
    }
  }

  # Organization scope only: org-level secrets.
  # Project discovery is handled by the harness-organization entrypoint, not this module.
  org_categories = local.scope == "organization" ? {
    secrets = {
      global_dir = "${local.source_directory}/secrets"
      org_dir    = "${local.config_directory}/secrets"
      patterns   = ["*.yaml"]
      key_fn     = "path"
    }
  } : {}

  # Project scope only: IACM workspaces and pipelines.
  project_categories = local.scope == "project" ? {
    workspaces = {
      global_dir = "${local.source_directory}/workspaces"
      org_dir    = "${local.config_directory}/workspaces"
      patterns   = ["*.yaml"]
      key_fn     = "path"
    }
    pipelines = {
      global_dir = "${local.source_directory}/pipelines"
      org_dir    = "${local.config_directory}/pipelines"
      patterns   = ["*.yaml"]
      key_fn     = "path"
    }
  } : {}

  # Services can be defined at any scope level (account, org, or project).
  # They are added separately to support all scope levels.
  service_categories = {
    services = {
      global_dir = "${local.source_directory}/services"
      org_dir    = "${local.config_directory}/services"
      patterns   = ["*.yaml"]
      key_fn     = "path"
    }
  }

  categories = merge(local.base_categories, local.org_categories, local.project_categories, local.service_categories)

  ##############################################################################
  # Merge logic
  # For each category, build a map keyed by the relative file path (or folder
  # name for folder-keyed categories).  The org-specific directory is merged
  # last so its entries win when the same key exists in both sides.
  #
  # Key derivation strips both .yaml and .rego extensions so policy identifiers
  # do not carry the file extension.
  ##############################################################################

  merged_sources = {
    for cat, cfg in local.categories :
    cat => merge(
      # Global defaults side
      {
        for rel in distinct(flatten([for p in cfg.patterns : try(fileset(cfg.global_dir, p), [])])) :
        (cfg.key_fn == "folder"
          ? basename(dirname(rel))
          : replace(replace(rel, ".yaml", ""), ".rego", "")
          ) => {
          origin = "global"
          name = lookup(
            try(yamldecode(file("${cfg.global_dir}/${rel}")), {}),
            "name",
            cfg.key_fn == "folder"
            ? basename(dirname(rel))
            : replace(replace(replace(replace(rel, ".yaml", ""), ".rego", ""), " ", "_"), "-", "_")
          )
          identifier = (
            cfg.key_fn == "folder"
            ? basename(dirname(rel))
            : replace(replace(replace(replace(rel, ".yaml", ""), ".rego", ""), " ", "_"), "-", "_")
          )
          dir  = cfg.global_dir
          file = rel
          cnf  = try(yamldecode(file("${cfg.global_dir}/${rel}")), {})
        }
      },
      # Scope-specific override side — wins on key collision
      {
        for rel in distinct(flatten([for p in cfg.patterns : try(fileset(cfg.org_dir, p), [])])) :
        (cfg.key_fn == "folder"
          ? basename(dirname(rel))
          : replace(replace(rel, ".yaml", ""), ".rego", "")
          ) => {
          origin = "org"
          name = lookup(
            try(yamldecode(file("${cfg.org_dir}/${rel}")), {}),
            "name",
            cfg.key_fn == "folder"
            ? basename(dirname(rel))
            : replace(replace(replace(replace(rel, ".yaml", ""), ".rego", ""), " ", "_"), "-", "_")
          )
          identifier = (
            cfg.key_fn == "folder"
            ? basename(dirname(rel))
            : replace(replace(replace(replace(rel, ".yaml", ""), ".rego", ""), " ", "_"), "-", "_")
          )
          dir  = cfg.org_dir
          file = rel
          cnf  = try(yamldecode(file("${cfg.org_dir}/${rel}")), {})
        }
      }
    )
  }
}

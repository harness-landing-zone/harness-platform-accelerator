# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a Terraform/OpenTofu-based **Harness Platform Accelerator** that manages Harness accounts, organizations, and projects using Infrastructure as Code. It follows a multi-scope architecture where configuration is managed through YAML files and merged from global templates with scope-specific overrides.

## Commands

### Initialization
```bash
# Initialize Terraform/OpenTofu with GCS backend (bootstrap)
tofu init \
  -backend-config="bucket=harness-backend-mk" \
  -backend-config="prefix=harness/platform_accelerator"

# Or standard init for local state
tofu init
```

### Planning and Applying
```bash
# Account-level setup
cd harness-platform-bootstrap
tofu plan
tofu apply

# Organization-level (auto-discovers projects)
cd harness-platform-deployment
tofu plan -var="scope_level=organization" -var="organization_name=Example Org One"
tofu apply

# Project-level (standalone)
cd harness-platform-deployment
tofu plan -var="scope_level=project" -var="organization_name=Example Org One" -var="project_name=Example Project One"
tofu apply

# IACM Workspace creation/import
cd workspace-creation
tofu plan
tofu apply
```

### Validation
```bash
# Format check
tofu fmt -check -recursive

# Validate configuration
tofu validate
```

## Architecture

### Three-Tier Scope Hierarchy

The codebase is structured around Harness's three resource scopes:

1. **Account** (`harness-platform-bootstrap/`) — One-time account baseline setup
2. **Organization** (`harness-platform-deployment/` with `scope_level=organization`) — Creates org + discovers all projects
3. **Project** (`harness-platform-deployment/` with `scope_level=project`) — Standalone project or invoked by org

### Core Module: `modules/harness-resources`

This is the **central workhorse module** used by all three entrypoints. Key responsibilities:

- **Scope detection** (locals.tf) — Determines whether it's running at account/org/project level based on input variables
- **Template merging** (locals-merge.tf) — Implements a two-layer merge system:
  - **Layer 1 (global)**: `<templates_root>/<template_name>/<category>/` (e.g., `templates/groups/`)
  - **Layer 2 (override)**: `platform-configs/organizations/<org>/<category>/` or `.../projects/<project>/<category>/`
  - Files with matching relative paths: Layer 2 wins
  - Files only in Layer 1: Included unchanged
- **Resource provisioning** — Creates all Harness resources (groups, roles, environments, policies, connectors, etc.) based on merged YAML

### Configuration Pattern

```
platform-configs/
└── organizations/
    └── <Organization Name>/
        ├── config.yaml          # Org metadata + template selection
        ├── groups/              # Override/extend global group configs
        ├── roles/
        ├── resource_groups/
        ├── environments/
        ├── policies/            # .rego files
        ├── policy_sets/
        ├── git-connectors/
        ├── cloud-provider-connectors/
        └── projects/
            └── <Project Name>/
                ├── config.yaml  # Project metadata
                ├── groups/
                ├── workspaces/  # IACM workspaces (project-only)
                ├── services/    # CD services (project-only)
                └── pipelines/   # CD pipelines (project-only)
```

**Key insight**: The directory name becomes the identifier (with spaces→underscores, dashes→underscores) unless overridden by `identifier:` in the YAML. Filename (without extension) also becomes the resource identifier.

### Project Auto-Discovery

When `harness-platform-deployment` runs at **organization scope**, it:
1. Scans `platform-configs/organizations/<org>/projects/*/config.yaml`
2. For each found project, instantiates the `harness-resources` module with `scope=project`
3. This happens in `harness-platform-bootstrap/main.tf` via `for_each = local.project_instances`

### Workspace Creation Flow

`workspace-creation/` creates **IACM workspaces** that reference the deployment configurations:
- Naming convention:
  - Account: `account_setup`
  - Org: `<org_identifier>`
  - Project: `<org_identifier>_<project_id>`
- Workspaces are created in a fixed org/project (`harness_platform_accelerator/platform_management`)
- Variables are injected based on scope level (base, org, project vars)
- Supports import-or-create pattern via `workspace_import_id`

### Permission Validation

`harness_roles.tf` implements **live permission validation**:
- Queries `data.harness_platform_permissions.current` from the Harness API
- Filters valid permissions by scope (`account`, `organization`, `project`)
- Uses Terraform `precondition` lifecycle to fail fast if YAML contains invalid permissions for the target scope
- Only `ACTIVE` and `EXPERIMENTAL` permission statuses are allowed

### Group Management Patterns

`harness_groups.tf` distinguishes between:
- **Managed groups**: Created by Terraform, full lifecycle management
- **Existing groups**: Prefixed with `_` or have `scope_level: account` in YAML
  - Looked up via `data.harness_platform_usergroup`
  - Role bindings applied, but group itself not created
  - SSO-linked groups should be marked as existing to avoid Terraform conflicts
  - Lifecycle `ignore_changes` protects SSO fields from drift

### State Management

- **Backend**: GCS backend configured but optional (can use local state)
- **Independence**: Each entrypoint has its own state file
- **Caution**: No remote state locking enforced — coordinate manual runs
- The `workspace-creation` module manages workspaces that will later execute the actual Harness provisioning

## Critical Patterns

### Identifier Derivation
```hcl
# From locals.tf
org_identifier = lower(
  var.organization_id != null ? var.organization_id :
  try(local.org_config.identifier, null) != null ? local.org_config.identifier :
  var.organization_name != null ? replace(replace(var.organization_name, " ", "_"), "-", "_") :
  ""
)
```
Priority: explicit variable → config.yaml identifier → derived from name

### Resolved Scope IDs
```hcl
# From locals.tf - these are deterministic at plan time
resolved_org_id     = local.scope != "account" ? local.org_identifier : null
resolved_project_id = local.scope == "project" ? local.project_identifier : null
```
**Why this matters**: Using input-derived identifiers instead of data source IDs prevents "known after apply" cascade when modules have `depends_on`, avoiding forced replacements.

### Template Selection Cascade
```hcl
# From locals.tf
default_project_template = try(
  local.project_config.default_project_template,  # Project config.yaml
  local.org_config.default_project_template,      # Org config.yaml
  var.default_project_template                    # Variable default
)
```
Priority: project config → org config → variable

### Role Binding Identifier
```hcl
# From harness_groups.tf
identifier = "${group.identifier}_${binding.role}"
```
Must be unique per scope; combines group + role to guarantee uniqueness.

## Provider Constraints

- `harness/harness >= 0.31`
- `hashicorp/time ~> 0.9.1`
- Uses `time_sleep` resource after project creation (15s) to avoid race conditions

## Important Variables

- `scope_level`: `"account"` | `"organization"` | `"project"` — gates which resources are created
- `organization_name`: Display name, must match folder name in `platform-configs/organizations/`
- `project_name`: Display name for project
- `project_key`: Explicit folder name override (defaults to derived from `project_name`)
- `configs_root`: Absolute path to `platform-configs/` directory
- `templates_root`: Absolute path to template defaults directory
- `default_org_template` / `default_project_template`: Template folder names (default: `"templates"`)

## Modifying Resources

### Adding a new resource type
1. Add category definition in `modules/harness-resources/locals-merge.tf` under appropriate scope
2. Create `harness_<resource>.tf` in `modules/harness-resources/`
3. Implement `for_each` over `local.merged_sources["<category>"]`
4. Use `local.resolved_org_id` and `local.resolved_project_id` for scope

### Adding a new organization
1. Create `platform-configs/organizations/<Org Name>/config.yaml`
2. Add resource YAML files in category subdirectories
3. Run `harness-platform-deployment` with `scope_level=organization`

### Adding a new project
1. Create `platform-configs/organizations/<Org>/projects/<Project>/config.yaml`
2. Add project-specific overrides in category subdirectories
3. Re-run org deployment (auto-discovered) or run standalone with `scope_level=project`

## Built-in Identifiers

Harness built-in resources are prefixed with `_`:
- Roles: `_organization_admin`, `_project_viewer`, etc.
- Resource groups: `_all_resources_including_child_scopes`, `_all_project_level_resources`

These can be referenced directly in YAML `role_bindings` without creation.

## Harness Platform Resources Used

This codebase manages the following `harness_platform_*` Next Gen resources:

### Core Platform Structure
- `harness_platform_organization` — Top-level org container (org scope)
- `harness_platform_project` — Project within an org (project scope)

### RBAC & Access Control
- `harness_platform_roles` — Custom roles with permission sets
- `harness_platform_resource_group` — Resource scoping for RBAC
- `harness_platform_usergroup` — User groups (managed or SSO-linked)
- `harness_platform_role_assignments` — Binds roles to groups on resource groups

### Governance & Policy
- `harness_platform_policy` — OPA policies (.rego files)
- `harness_platform_policyset` — Policy collections with enforcement actions

### Connectors
- `harness_platform_connector_github` — GitHub App or token-based connector
- `harness_platform_connector_git` — Generic Git connector (GitLab, Bitbucket, etc.)
- `harness_platform_connector_aws` — AWS connector (OIDC, IRSA, manual, delegate)
- `harness_platform_connector_gcp` — GCP connector

### Environments & Secrets
- `harness_platform_environment` — Deployment environments (Production/PreProduction)
- `harness_platform_overrides` — Environment-specific variable overrides (V2)
- `harness_platform_secret_text` — Text-based secrets
- `harness_platform_secret_file` — File-based secrets

### CD/IACM Resources
- `harness_platform_service` — CD service definitions (any scope: account/org/project)
- `harness_platform_pipeline` — CD/CI pipelines (project-scope only, Git-imported)
- `harness_platform_workspace` — IACM (Terraform/OpenTofu) workspaces (project-scope only)

### Data Sources
- `data.harness_platform_permissions` — Live permissions API query for validation
- `data.harness_platform_usergroup` — Lookup existing groups (SSO-linked)
- `data.harness_platform_organization` — Resolve org after creation
- `data.harness_platform_project` — Resolve project after creation

## Resource Implementation Patterns

### Standard Resource Pattern
```hcl
resource "harness_platform_<resource>" "name" {
  for_each = local.scope == "<required_scope>" ? {
    for item in local.merged_sources["<category>"] : item.identifier => item
  } : {}

  identifier = each.value.identifier
  name       = each.value.name
  org_id     = local.resolved_org_id     # null for account scope
  project_id = local.resolved_project_id # null for non-project scope
  
  # Resource-specific fields from each.value.cnf (the parsed YAML)
  tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])
}
```

### Scope-Gated Resources
Categories in `locals-merge.tf` define which scopes they apply to:
- **base_categories**: Available at all scopes (account, org, project)
  - environments, groups, resource_groups, policy_sets, roles, policies, git-connectors, cloud-provider-connectors
- **org_categories**: Organization scope only
  - secrets (org-level secrets)
- **service_categories**: Available at all scopes (account, org, project)
  - services (CD service definitions)
- **project_categories**: Project scope only
  - workspaces (IACM workspaces), pipelines (CD/CI pipelines)

### Git-Imported Pipeline Pattern
```hcl
resource "harness_platform_pipeline" "pipelines" {
  # ... identifier, name, org_id, project_id ...
  import_from_git = true
  
  git_import_info {
    branch_name   = lookup(each.value.cnf, "git_branch", "main")
    file_path     = lookup(each.value.cnf, "git_file_path", ".harness/${each.key}.yaml")
    connector_ref = lookup(each.value.cnf, "git_connector_ref", "")
    repo_name     = lookup(each.value.cnf, "git_repo_name", "")
  }
  
  pipeline_import_request {
    pipeline_name        = each.value.name
    pipeline_description = lookup(each.value.cnf, "description", "...")
  }
  
  # Prevent drift after initial import
  lifecycle {
    ignore_changes = [git_import_info, pipeline_import_request]
  }
}
```

### Connector Authentication Patterns

**AWS Connector** (4 auth methods — exactly one required):
```hcl
# 1. OIDC (recommended for EKS)
oidc {
  iam_role_arn       = "arn:aws:iam::..."
  region             = "us-east-1"
  delegate_selectors = ["delegate-name"]
}

# 2. IRSA (for in-cluster delegates)
irsa {
  delegate_selectors = ["delegate-name"]
  region             = "us-east-1"
}

# 3. Manual (access key/secret)
manual {
  secret_key_ref     = "account.aws_secret_key"
  delegate_selectors = ["delegate-name"]
}

# 4. Inherit from delegate IAM role
inherit_from_delegate {
  delegate_selectors = ["delegate-name"]
}

# Optional cross-account (any auth method)
cross_account_access {
  role_arn    = "arn:aws:iam::..."
  external_id = "..."
}
```

**Git Connector** (GitHub vs Generic):
```hcl
# GitHub-specific (type: Github)
credentials {
  http {
    github_app {
      installation_id  = "123456"
      application_id   = "789"
      private_key_ref  = "account.github_app_key"
    }
  }
}
api_authentication {
  github_app {
    installation_id  = "123456"
    application_id   = "789"
    private_key_ref  = "account.github_app_key"
  }
}

# Generic Git (type: Git)
credentials {
  http {
    username        = "git-user"
    password_ref    = "account.git_token"
  }
}
```

### Service Account Connector Pattern
The `harness-platform-bootstrap/harness_service_accounts.tf` file manages service accounts for automated access. This is separate from the main `harness-resources` module and typically used for bootstrap/CI purposes.

## Adding New Harness Resource Types

When adding support for a new `harness_platform_*` resource:

1. **Determine scope** — Is it account/org/project only, or multi-scope?

2. **Add to `locals-merge.tf`**:
```hcl
# In base_categories (all scopes), org_categories, or project_categories
new_resource_type = {
  global_dir = "${local.source_directory}/<resource_type>"
  org_dir    = "${local.config_directory}/<resource_type>"
  patterns   = ["*.yaml"]  # or ["*.rego"] for policies
  key_fn     = "path"      # or "folder" for folder-keyed resources
}
```

3. **Create `harness_<resource>.tf`** in `modules/harness-resources/`:
```hcl
locals {
  resource_items = try(local.merged_sources["<resource_type>"], {})
}

resource "harness_platform_<resource>" "items" {
  depends_on = [/* dependencies */]
  
  for_each = local.scope == "<required_scope>" ? {
    for item in local.resource_items : item.identifier => item
  } : {}
  
  identifier = each.value.identifier
  name       = each.value.name
  org_id     = local.resolved_org_id
  project_id = local.resolved_project_id
  
  # Map YAML fields from each.value.cnf
  description = lookup(each.value.cnf, "description", "Managed by Solutions Factory")
  tags        = local.common_tags_tuple
}
```

4. **Document YAML schema** in README.md following existing patterns

5. **Create example YAML** in appropriate template folder for testing

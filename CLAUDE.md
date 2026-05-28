# Harness Platform Accelerator — Working Reference

> A parent `CLAUDE.md` one level up (`harness-landing-zone/CLAUDE.md`) also loads and holds the
> **mandatory Harness-doc-verification rules** (never guess Harness YAML/step types/expressions —
> verify against docs). Those still apply. This file is the repo-level code reference.

## 1. Project overview

IaC accelerator that automates creation of **Harness platform resources** — orgs, projects,
connectors (git + cloud), pipelines, RBAC (roles/resource-groups/user-groups/bindings),
governance (policies/policy-sets), environments, secrets, and IACM workspaces. **Tool: OpenTofu**
(`opentofu`, provider `harness/harness >= 0.31`). It is **config-as-data**: you describe the desired
platform as YAML files and the modules realize them. "Done" = a `tofu plan` that is clean/idempotent
and an `apply` that converges the target org/project/account to the YAML, runnable repeatably with
no drift. Purpose: let the platform team stand up and extend Harness resources fast; actively being
**extended to bootstrap more resource types**.

## 2. Architecture

**Root modules (entrypoints):**
- `harness-platform-deployment/` — main entrypoint. Normally runs **inside a Harness IACM workspace**
  (which owns state). Calls the core module **four mutually-exclusive ways** gated on `scope_level`:
  `module.account` · `module.organization` · `module.projects` (`for_each` over discovered projects,
  `depends_on` org) · `module.project` (single project into an existing org — the IDP flow).
- `harness-platform-bootstrap/` — bootstraps the live `harness_platform_accelerator` org + Platform
  Management project + service accounts. **GCS backend.**
- `workspace-creation/` — standalone; find-or-create the IACM workspace that *runs* the deployment
  (import-or-create via `harness_platform_workspaces` data source, stateless `/tmp/ws.tfstate`).

**Child modules (`modules/`):**
- `harness-resources/` — **the core "do everything" module.** Creates org/project + all scoped
  resources, and itself calls the three connector/workspace child modules.
- `cloud-provider-connectors/` — AWS + GCP (`count`-gated per type, auth modes as `dynamic` blocks).
- `git-connectors/` — GitHub + generic Git (same pattern).
- `iacm-workspaces/` — single `harness_platform_workspace` (project scope only).

```
harness-platform-deployment ─┬─ module.account ───────┐
                             ├─ module.organization ──┼─> modules/harness-resources ─┬─ git-connectors
                             ├─ module.projects (N) ───┤                              ├─ cloud-provider-connectors
                             └─ module.project ────────┘                              └─ iacm-workspaces (project only)
workspace-creation ─> modules/iacm-workspaces
```

**Scope is auto-detected inside `harness-resources`** (`locals.tf`): `project_name` set → `project`;
only `organization_name` set → `organization`; neither → `account`. Callers pick scope by which vars
they pass — there is no `scope` input to the core module.

**Source of truth = YAML config trees**, merged in two layers (override wins):
1. **Global defaults** ("templates") shipped in the deployment entrypoint:
   `account-config/`, `org-default-config/`, `project-default-config/`.
2. **Scope overrides**: `platform-configs/organizations/<org>/[projects/<proj>/]<category>/*.yaml`.

There are two `platform-configs/` trees on purpose: the bundled one (`platform_configs_repo_name`
default `local-repo`) and an externally-cloned config repo (`tofu_deploy_iacm` Stage 4 `GitClone`
into `platform-configs/<repo_name>/`). Folder names ARE the keys; the org folder is the
`organization_name`.

## 3. Conventions  ← match these exactly; new code should be indistinguishable

**File layout (every module):** `main.tf`, `variables.tf`, `outputs.tf`, `terraform.tf`.
The core module additionally: **one file per resource type** named `harness_<type>.tf`
(`harness_environments.tf`, `harness_roles.tf`, `harness_groups.tf`, …); `locals.tf` for
scope/path/identifier resolution; `locals-merge.tf` for the config discovery + merge engine.

**The resource pattern (copy this for any new resource type):**
```hcl
# harness_<type>.tf
locals {
  <type> = local.merged_sources["<category>"]   # category defined in locals-merge.tf
}
resource "harness_platform_<type>" "<type>" {
  for_each    = { for x in local.<type> : x.name => x }   # or x.identifier => x
  identifier  = each.value.identifier
  name        = each.value.name
  org_id      = local.resolved_org_id            # NOT the data source (see gotchas)
  project_id  = local.resolved_project_id
  description = lookup(each.value.cnf, "description", "… managed by Solutions Factory")
  tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple,
  ])
  # all other fields via lookup(each.value.cnf, "field", <default>) / try(each.value.cnf.field, …)
}
```
Each merged entry is `{ origin, name, identifier, dir, file, cnf }` where `cnf` is the decoded YAML.

**Adding a category:** register it in `locals-merge.tf` under `base_categories` (all scopes),
`org_categories` (org only), or `project_categories` (project only), with `global_dir`/`org_dir`/
`patterns`/`key_fn`. Then create the matching default templates under the `*-default-config/` dirs.

**Identifiers:** always `lower(replace(replace(x, " ", "_"), "-", "_"))`. Resolution order:
explicit `*_id` var → `identifier` in the YAML → normalized `name`/filename. Filenames drive
name+identifier when YAML omits them.

**Tagging:** `local.required_tags` (`created_by=Terraform`, `template=<template>`,
`platform_configs_repo_name`) `merge`d with `var.tags`, exposed as the Harness `["key:value"]`
tuple `local.common_tags_tuple`. Per-resource YAML `tags:` maps are flattened and appended (above).

**Variables:** typed; description prefixed `[Required]`/`[Optional]`; sensible `default`; `sensitive
= true` for anything secret (`git_connector_credentials`, `secret_values`). Connector/workspace
child modules expose granular `dynamic`-block inputs (one optional object var per auth mode/feature).

**Optionality style (per parent CLAUDE.md):** use `try(...)`, `lookup(map, key, default)`, and
`var.x != null && trimspace(var.x) != "" ? var.x : null`. **Do not** `coalesce()` on nullable values.

**Validation:** use `lifecycle { precondition { … } }` for "exactly one of" constraints (auth modes,
workspace ref source). Roles validate permissions live against `data.harness_platform_permissions`.

**Scope IDs:** resources set `org_id`/`project_id` from `local.resolved_org_id` /
`local.resolved_project_id` (input-derived, known at plan time). The `data.harness_platform_*`
sources exist for validation/extra fields only — don't wire them into resource scoping.

## 4. State & auth

- **Backends:** `harness-platform-bootstrap` → GCS (`backend "gcs" {}`, init with `-backend-config`).
  `harness-platform-deployment` → GCS block is **commented out** because it runs in Harness IACM,
  which manages state. `workspace-creation` → stateless (`-backend=false`, `/tmp/ws.tfstate`).
- **Harness provider auth:** there is **no `provider "harness"` block** — it reads env vars
  `HARNESS_ACCOUNT_ID`, `HARNESS_PLATFORM_API_KEY` (secret ref), `HARNESS_ENDPOINT`. The IACM
  workspace injects these (set in `workspace-creation/workspace.tf`).
- **Cloud auth: OIDC-first.** AWS via OIDC IAM role ARN; GCP via WIF (workload pool/provider) — no
  static SA keys. GCS backend via GCP OIDC token exchange.
- **Git creds** stay out of YAML: pass via the sensitive `git_connector_credentials` tfvars map
  (keyed by connector identifier); used only when the connector YAML omits the credential block.

## 5. Commands

```bash
# Format + validate (run from any module dir; fmt is recursive from root)
tofu fmt -recursive
tofu validate

# Bootstrap (GCS backend)
cd harness-platform-bootstrap
tofu init -backend-config="bucket=<bucket>" -backend-config="prefix=harness/platform_accelerator"
tofu plan   # then: tofu apply

# Deployment, run locally (provider reads env vars — export first)
export HARNESS_ACCOUNT_ID=…  HARNESS_PLATFORM_API_KEY=…  HARNESS_ENDPOINT=https://app.harness.io/gateway
cd harness-platform-deployment
tofu init
tofu plan  -var 'scope_level=organization' -var 'organization_name=<Org>'
tofu plan  -var 'scope_level=project'      -var 'organization_name=<Org>' -var 'project_name=<Proj>'
```
- Credentials/overrides go in a **gitignored `terraform.tfvars`** (e.g. `git_connector_credentials`).
- Normal production path is the Harness pipeline `tofu_deploy_iacm` (init → plan → approve → apply),
  not local runs.

## 6. Rules / guardrails

- **Always `tofu fmt -recursive` and `tofu validate` before finishing** any change.
- **Never hardcode** account IDs or Harness identifiers in `.tf` — they come from env vars, tfvars,
  or `config.yaml`. **Never put secrets in YAML** — use `git_connector_credentials`/`secret_values`
  tfvars or Harness secret refs.
- **Follow the resource pattern** in §3 for any new resource type: category in `locals-merge.tf`
  → `harness_<type>.tf` reading `local.merged_sources[...]` → default templates under
  `*-default-config/`. Don't invent a new structure.
- **Keep plans clean and idempotent:** scope with `resolved_*_id`, not data sources; preserve the
  `lifecycle { ignore_changes }` on user groups (users/SSO are managed outside TF).
- **Verify Harness YAML/expressions against docs** before writing pipeline/step/expression syntax
  (parent CLAUDE.md). In shell steps use `.` not `source`; use `<+input>.default()` not `coalesce()`.
- **Build on `harness_platform_accelerator`** (the live bootstrap org); do not extend the legacy
  `platform_bootstrap` org.
- **Never commit or push.** All git commits/pushes are done by the user only.

## 7. Gotchas

- **Scope is implicit** — set the wrong combination of `organization_name`/`project_name` and you
  silently target a different scope. No explicit `scope` input on the core module.
- **`resolved_org_id` vs data source:** resources deliberately use the input-derived IDs; switching
  to `data.harness_platform_*.id` makes scoping "known after apply" and causes spurious replacements.
- **`time_sleep "project_setup"` (15s)** after project creation guards an API race — keep it.
- **Role permissions are validated live** against `data.harness_platform_permissions`; an unknown or
  wrong-scope permission in a role YAML fails the plan with a precondition error.
- **Secrets are org-scope only**; text secret values are not in YAML — they come from the
  `secret_values` tfvars map keyed by identifier. File secrets read from `pem_path`.
- **Environments** can carry a `yaml:` block → emits a second `harness_platform_overrides`
  (`ENV_GLOBAL_OVERRIDE`); note the regex in `harness_environments.tf` that fixes quoted keys.
- **Two `platform-configs/` trees are intentional** (bundled `local-repo` vs cloned repo) — not a
  duplicate to "clean up". Org folder path currently uses `organization_name` raw (identifier
  normalization is a known TODO).
- **`default_*_template`** in a `config.yaml` switches which global-defaults tree is used per org/
  project (e.g. `templates-two`).

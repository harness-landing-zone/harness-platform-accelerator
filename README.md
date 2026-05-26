# Custom Harness Template Library

OpenTofu/Terraform templates for managing a Harness account, organizations, and projects using the `harness/harness` provider.

## Overview

This library provides three independent Terraform entrypoints that map to Harness's three resource scopes.

```
Account ──► harness-platform-setup/
Org     ──► harness-organization/   (also discovers and instantiates projects)
Project ──► harness-project/        (reusable module, called directly or by org)
```

Each entrypoint manages:

| Resource | platform-setup | organization | project |
|---|:---:|:---:|:---:|
| Roles | ✓ | ✓ | ✓ |
| Resource Groups | ✓ | ✓ | ✓ |
| User Groups + Role Bindings | ✓ | ✓ | ✓ |
| Environments + Overrides | ✓ | ✓ | ✓ |
| OPA Policies + Policy Sets | ✓ | ✓ | ✓ |
| Git Connectors | ✓  | ✓ | ✓ |
| Cloud Provider Connectors (AWS) | ✓ | ✓ | ✓ |

---

## Prerequisites

- [OpenTofu](https://opentofu.org/docs/intro/install/) (`tofu`) **or** [Terraform](https://developer.hashicorp.com/terraform/install) (`terraform`)
- A Harness account with an API key that has account-admin permissions
- The `harness/harness` provider `>= 0.31` and `hashicorp/time ~> 0.9.1` (fetched automatically by `tofu init`)

---

## Deployment Workflow

### 1. Account baseline — `harness-platform-setup/`

Run this once when setting up a new Harness account. Creates account-scoped roles, resource groups, user groups, OPA policies, and environments.



`terraform.tfvars` minimum content:

```hcl
harness_platform_account = "abc123xyz"
tags = {}
```

---

### 2. Organization + Projects — `harness-organization/`

Run this once per Harness organization. Creates the org, applies org-scoped resources, and automatically discovers and creates all projects under that org from `platform-configs/organizations/<org-name>/projects/`.

`terraform.tfvars` minimum content:

```hcl
harness_platform_account = "abc123xyz"
organization_name        = "My Org"   # Must match folder name in platform-configs/organizations/
```

> **Project discovery is automatic.** Any folder matching `platform-configs/organizations/<org-name>/projects/*/config.yaml` is instantiated as a Harness project. No variables list required.

---

### 3. Standalone project — `harness-project/`

Use this entrypoint directly when creating a single project outside of org-level discovery.

`terraform.tfvars` minimum content:

```hcl
harness_platform_account = "abc123xyz"
organization_id          = "My_Org"
project_name             = "My Project"
```

---

## Configuration — How the YAML Workflow Works

### Directory layout

```
platform-configs/
└── organizations/
    └── <Organization Name>/            # Folder name == organization_name variable
        ├── config.yaml                 # Org metadata (name, description, tags)
        ├── groups/
        ├── roles/
        ├── resource_groups/
        ├── environments/
        ├── policies/
        ├── policy_sets/
        ├── git-connectors/
        ├── cloud-provider-connectors/
        └── projects/
            └── <Project Name>/         # Folder name == project identifier
                ├── config.yaml         # Project metadata
                ├── groups/
                ├── roles/
                ├── resource_groups/
                ├── environments/
                ├── policies/
                ├── policy_sets/
                ├── git-connectors/
                └── cloud-provider-connectors/
```

### Override / merge resolution

For `harness-organization` and `harness-project`, every resource category is merged from two sources:

1. **Global defaults** — `<entrypoint>/<template_folder>/<category>/` where `<template_folder>` defaults to `templates` and is configurable via the `default_org_template` / `default_project_template` variable or `config.yaml` field.
2. **Org or project overrides** — `platform-configs/organizations/<org>/<category>/` (or `.../projects/<project>/<category>/`)

When a file exists in both locations with the **same relative path**, the org/project version wins. Files only in the global defaults are included unchanged. This means you can ship sensible defaults in `templates/` and only place YAML files in `platform-configs/` for what you want to change or add.

For `harness-platform-setup`, there is no merge — it reads exclusively from `harness-platform-setup/templates/`.

### Resource identifier derivation

The Harness resource identifier is derived from the **filename** (without `.yaml`), with spaces and dashes replaced by underscores. You can override this by setting `identifier:` explicitly in the YAML.

---

## YAML Schema Reference

### `config.yaml` (org or project root)

```yaml
name: "My Organization"           # Display name
description: "..."                # Optional
identifier: "my_org"              # Optional — overrides filename-derived identifier
default_org_template: "templates-two"     # Optional — org-level template folder to use instead of the default "templates"
default_project_template: "templates-two" # Optional — project-level template folder to use for all projects under this org,
                                          #            or for a specific project when set in that project's config.yaml.
                                          #            Priority: project config.yaml > org config.yaml > variable default
tags:
  owner: platform-team
  env: prod
```

### Groups (`groups/*.yaml`)

```yaml
scope_level: account # Group already exst in th eacocunt level so it will be Inherited to the relevant scope
name: "Platform Admins"
tags:
  purpose: admins

# SSO linking (all optional)
linked_sso_type: "SAML"
linked_sso_id: "saml-provider-id"
sso_group_id: "saml-group-id"
sso_group_name: "Platform Admins"

# Role bindings granted to this group
role_bindings:
  - role: _organization_admin                          # Built-in or custom role identifier
    resource_group: _all_resources_including_child_scopes
  - role: my_custom_role
    resource_group: my_resource_group
```

> **Existing groups** (pre-created outside Terraform, e.g. SSO-synced): prefix the filename with `_` (e.g. `_existing_admins.yaml`). Terraform will look up the group by identifier and assign role bindings without trying to create it. or by adding the value

### Roles (`roles/*.yaml`)

```yaml
name: "Developer"
permissions:
  - core_pipeline_view
  - core_pipeline_execute
  - core_environment_view
  - core_service_view
  - core_connector_view
  - core_secret_view
```

> Valid permissions are validated at plan time against the live Harness API. Invalid permissions cause a `precondition` failure with a clear error listing the invalid entries.

### Resource Groups (`resource_groups/*.yaml`)

```yaml
name: "Production Environments"
description: "Access to production environments only"
color: "#0063F7"
included_scopes:
  - filter: INCLUDING_CHILD_SCOPES
    account_id: "<account_id>"
resource_filters:
  - resource_type: ENVIRONMENT
    filters:
      - name: type
        values:
          - Production
  - resource_type: PIPELINE
    filters: []     # Empty = all pipelines
```

### Environments (`environments/*.yaml`)

```yaml
name: "Production"
type: Production          # PreProduction | Production
description: "..."
tags:
  env: prod
```

With environment override YAML (V2 overrides):

```yaml
name: "Production"
type: Production
yaml:
  environmentRef: production
  variables:
    - name: region
      value: eu-west-1
      type: String
```

### Policies (`policies/*.rego`)

Policy files use the `.rego` extension. The filename (without `.rego`) becomes the identifier and display name.

```rego
package pipeline

deny[msg] {
  input.pipeline.stages[_].stage.spec.execution.steps[_].step.type == "ShellScript"
  msg := "ShellScript steps are not allowed"
}
```

### Policy Sets (`policy_sets/*.yaml`)

```yaml
name: "Mandatory Pipeline Policies"
action: onrun                  # onrun | onsave | onstep | afterTerraformPlan
type: pipeline                 # pipeline | template | inputset | ...
policies:
  - identifier: enforce_template_version_schema
    severity: error            # error | warning
  - identifier: my_custom_policy
    severity: warning
```

### Git Connectors (`git-connectors/*.yaml`)

**GitHub connector (GitHub App auth):**

```yaml
name: "Platform GitHub Connector"
type: Github                          # Github | Git
description: "..."
tags:
  provider: github
connector_url: https://github.com/my-org
connection_type: Account              # Account | Repo
validation_repo: my-validation-repo
execute_on_delegate: false
http_credentials:
  github_app:
    application_id: "123456"
    installation_id: "789012"
    private_key_ref: account.my_github_app_key
api_auth:
  github_app_api: true
```

**Generic Git connector (username/token):**

```yaml
name: "Internal Git Connector"
type: Git
connector_url: https://git.internal.example.com/my-org
connection_type: Account
validation_repo: my-repo
execute_on_delegate: true
delegate_selectors:
  - internal-delegate
http_credentials:
  username: git-user
  password_ref: account.git_token
```

### Cloud Provider Connectors (`cloud-provider-connectors/*.yaml`)

The `type` field selects the provider. Currently only `aws` is supported.

**OIDC (recommended for EKS/IRSA):**

```yaml
type: aws
name: "AWS OIDC Connector"
execute_on_delegate: false
oidc_authentication:
  iam_role_arn: "arn:aws:iam::123456789012:role/HarnessOIDCRole"
  region: "eu-west-1"
  delegate_selectors:
    - my-delegate
```

**IRSA:**

```yaml
type: aws
name: "AWS IRSA Connector"
execute_on_delegate: true
irsa_authentication:
  iam_role_arn: "arn:aws:iam::123456789012:role/HarnessIRSARole"
  delegate_selectors:
    - my-delegate
```

**Manual (access key/secret):**

```yaml
type: aws
name: "AWS Manual Connector"
execute_on_delegate: true
manual_authentication:
  access_key_ref: account.aws_access_key
  secret_key_ref: account.aws_secret_key
  delegate_selectors:
    - my-delegate
  region: "eu-west-1"
```

**Inherit from delegate:**

```yaml
type: aws
name: "AWS Delegate Connector"
execute_on_delegate: true
inherit_from_delegate:
  delegate_selectors:
    - my-delegate
```

With optional cross-account access (any auth type):

```yaml
cross_account_access:
  role_arn: "arn:aws:iam::999999999999:role/HarnessCrossAccount"
  external_id: "harness-external-id"
```

---

## Modules Reference

### `modules/git-connectors`

Supports `Github` and `Git` connector types. The `connector_type` variable controls which Harness resource is created. All credential fields are optional — pass only what your YAML contains.

| Variable | Required | Description |
|---|:---:|---|
| `connector_type` | ✓ | `Github` or `Git` |
| `connector_name` | ✓ | Display name |
| `connector_identifier` | ✓ | Harness identifier |
| `git_connector_url` | ✓ | Repository or account URL |
| `connection_type` | ✓ | `Account` or `Repo` |
| `git_connector_http_credentials` | — | HTTP auth block (username/password or GitHub App) |
| `git_connector_ssh_credentials` | — | SSH auth block |
| `git_connector_api_auth` | — | API auth (required for Git Experience) |
| `org_id`, `project_id` | — | Scope; omit for account-level |

### `modules/cloud-provider-connectors`

AWS only. Exactly one authentication mode must be provided; the module enforces this with a `precondition`.

| Variable | Required | Description |
|---|:---:|---|
| `connector_name` | ✓ | Display name |
| `connector_identifier` | ✓ | Harness identifier |
| `aws_connector_oidc_authentication` | — | OIDC auth object |
| `aws_connector_irsa_authentication` | — | IRSA auth object |
| `aws_connector_manual_authentication` | — | Access key / secret key object |
| `aws_connector_inherit_from_delegate` | — | Delegate inherit object |
| `aws_connector_cross_account_access` | — | Cross-account role ARN |
| `org_id`, `project_id` | — | Scope; omit for account-level |

---

## Adding a New Organization

1. Create the folder: `platform-configs/organizations/<Org Name>/`
2. Add `config.yaml`:
   ```yaml
   name: "Org Name"
   description: "..."
   tags:
     owner: platform-team
   ```
3. Add any resource YAML files in the relevant category subdirectories (groups, roles, etc.).
4. Run `harness-organization/` with `organization_name = "Org Name"`.

## Adding a New Project

1. Create the folder: `platform-configs/organizations/<Org Name>/projects/<Project Name>/`
2. Add `config.yaml`:
   ```yaml
   name: "Project Name"
   description: "..."
   ```
3. Add project-specific YAML overrides as needed. Any category you leave empty will inherit from `harness-project/templates/`.
4. Re-run `harness-organization/` — the project is discovered and created automatically.

---

## RBAC Design Conventions

| Scope | Principle |
|---|---|
| Account | `iacm-admin` role, account-wide admin groups, OPA governance |
| Organization | Org-admin groups, shared resource groups, org-scoped connectors |
| Project | Developer/release-manager groups, pipeline-scoped environments, IACM workspace permissions |

- `iacm_workspace_*` permissions are **project-scoped only** (not valid at account or org scope).
- Environment access is granted through **Resource Groups** (filter by env type), not role permissions directly.
- Harness built-in identifiers (e.g. `_organization_admin`, `_all_resources_including_child_scopes`) are prefixed with `_` and referenced directly in `role_bindings`.

---

## State Management

This repo uses **local state only**. Each entrypoint maintains its own `terraform.tfstate` file within its directory.

- Do not configure a remote backend unless you intend to migrate.
- Run one entrypoint at a time — they are independent.
- Commit `terraform.tfstate` files only if your team has agreed on a shared local-state workflow; otherwise keep them local and gitignored.

---

## Provider / Resource Notes

- Provider: `harness/harness >= 0.31`, `hashicorp/time ~> 0.9.1`
- `harness_platform_role_assignments.identifier` must be unique per scope; the library derives it as `<group_identifier>_<role_identifier>`.
- `harness_platform_usergroup` SSO fields are in the `lifecycle { ignore_changes }` block — SSO linking managed outside Terraform will not be overwritten on subsequent runs.
- `harness_platform_permissions` is fetched live at plan time to validate role permissions against the actual account.

---

## License

MIT. See `LICENSE`.

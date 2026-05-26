# Harness IACM Workspaces Module

Reusable Harness IACM Workspace module built on `harness_platform_workspace`.

This module is written for the `harness/harness` provider and creates project-scoped IACM workspaces with explicit repository settings, variable blocks, connector blocks, and optional default pipelines.

## What It Creates

- `harness_platform_workspace`

Scope is project-only for this module (both `org_id` and `project_id` are required).

## Usage

```hcl
module "iacm_workspace" {
  source = "../modules/iacm-workspaces"

  workspace_name        = "network-foundation"
  workspace_identifier  = "network_foundation"
  workspace_description = "OpenTofu workspace for shared network infra"
  workspace_tags        = ["owner:platform-team", "env:shared"]

  org_id     = "my_org"
  project_id = "my_project"

  cost_estimation_enabled = true
  provisioner_type        = "opentofu"
  provisioner_version     = "1.8.8"

  repository           = "https://github.com/example/platform-infra"
  repository_connector = "account.my_github_connector"
  repository_path      = "live/aws/network"
  repository_branch    = "main"

  workspace_connectors = [
    {
      connector_ref = "account.aws_oidc_connector"
      type          = "aws"
    }
  ]

  terraform_variables = [
    {
      key        = "aws_region"
      value      = "us-east-1"
      value_type = "string"
    }
  ]

  environment_variables = [
    {
      key        = "TF_VAR_environment"
      value      = "shared"
      value_type = "string"
    }
  ]

  terraform_variable_files = [
    {
      repository           = "https://github.com/example/platform-infra"
      repository_connector = "account.my_github_connector"
      repository_path      = "vars/shared/network.tfvars"
      repository_branch    = "main"
    }
  ]

  variable_sets = [
    "account.shared_iacm_vars"
  ]

  default_pipelines = {
    plan    = "iacm_plan"
    apply   = "iacm_apply"
    destroy = "iacm_destroy"
    drift   = "iacm_drift"
  }
}
```

## Requirements

| Name | Version |
| --- | --- |
| **Terraform/OpenTofu** | >= 1.0.0 |
| **Harness Provider** | ~> 0.40 |

## Inputs

### Core Configuration

| Name | Description | Type | Default |
| --- | --- | --- | --- |
| `workspace_name` | Name of the workspace. | `string` | **Required** |
| `workspace_identifier` | Unique identifier of the workspace. | `string` | `null` |
| `workspace_description` | Description of the workspace. | `string` | `null` |
| `workspace_tags` | Tags to associate with the workspace. | `set(string)` | `[]` |
| `org_id` | Harness organization identifier. | `string` | **Required** |
| `project_id` | Harness project identifier. | `string` | **Required** |

### Provisioner + Repository

| Name | Description | Type | Default |
| --- | --- | --- | --- |
| `cost_estimation_enabled` | Enable cost estimation for the workspace. | `bool` | **Required** |
| `provisioner_type` | Provisioner type (`terraform` or `opentofu`). | `string` | **Required** |
| `provisioner_version` | Provisioner version for the workspace runtime. | `string` | **Required** |
| `repository` | Repository URL/name to fetch code from. | `string` | **Required** |
| `repository_connector` | Harness connector reference for the repository. | `string` | **Required** |
| `repository_path` | Path in the repository for workspace code. | `string` | **Required** |
| `repository_branch` | Branch selector (exactly one of branch/commit/sha is required). | `string` | `null` |
| `repository_commit` | Tag selector (exactly one of branch/commit/sha is required). | `string` | `null` |
| `repository_sha` | SHA selector (exactly one of branch/commit/sha is required). | `string` | `null` |
| `provider_connector` | Deprecated provider connector field (prefer `workspace_connectors`). | `string` | `null` |

### Nested Blocks / Associations

| Name | Description | Type | Default |
| --- | --- | --- | --- |
| `workspace_connectors` | Workspace `connector` blocks (one per type). | `list(object)` | `[]` |
| `terraform_variables` | Workspace `terraform_variable` blocks. | `list(object)` | `[]` |
| `environment_variables` | Workspace `environment_variable` blocks. | `list(object)` | `[]` |
| `terraform_variable_files` | Workspace `terraform_variable_file` blocks. | `list(object)` | `[]` |
| `variable_sets` | Harness variable set references. | `list(string)` | `[]` |
| `default_pipelines` | Default pipeline IDs by operation. | `map(string)` | `{}` |

## Outputs

- `workspace_id`
- `workspace_identifier`
- `workspace_name`

## Validation Notes

- Enforces that exactly one of `repository_branch`, `repository_commit`, or `repository_sha` is set.
- Enforces one `workspace_connectors` entry per connector type (`aws`, `azure`, `gcp`).
- Enforces variable `value_type` values (`string`, `secret`).

## References (Official Harness Terraform Provider Docs)

- `harness_platform_workspace` resource docs (Terraform Registry): https://registry.terraform.io/providers/harness/harness/latest/docs/resources/platform_workspace

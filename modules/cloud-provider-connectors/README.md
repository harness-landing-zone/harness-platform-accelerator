# Cloud Provider Connectors Module (AWS)

Reusable Harness AWS connector module built on `harness_platform_connector_aws`.

This module is written for the `harness/harness` provider and supports multiple AWS auth modes, including AWS OIDC (preferred for this repo wiring).

## What It Creates

- `harness_platform_connector_aws`

Scope is controlled by optional inputs:

- account scope: omit `org_id` and `project_id`
- organization scope: set `org_id`, omit `project_id`
- project scope: set both `org_id` and `project_id`

## Auth Modes

Exactly one auth mode must be set (enforced by lifecycle preconditions):

- `aws_connector_oidc_authentication` (preferred)
- `aws_connector_inherit_from_delegate`
- `aws_connector_irsa_authentication`
- `aws_connector_manual_authentication`

This repo's new wiring files intentionally use AWS OIDC only (no access keys).

## AWS OIDC Example

```hcl
module "aws_oidc_connector" {
  source = "../modules/cloud-provider-connectors"

  connector_name        = "AWS OIDC Connector"
  connector_identifier  = "aws_oidc_connector"
  connector_description = "Harness AWS connector using OIDC"
  connector_tags        = ["owner:platform-team"]

  execute_on_delegate = true

  aws_connector_oidc_authentication = {
    iam_role_arn       = "arn:aws:iam::123456789012:role/harness-oidc-role"
    region             = "us-east-1"
    delegate_selectors = ["aws-delegate"]
  }
}
```

## Folder-Driven YAML Schema (Used by Repo Wiring)

The repo-level wiring (`harness_git_connctors.tf`) expects `.yaml` files with this shape:

```yaml
type: aws
auth_type: oidc
name: "AWS OIDC Connector"
description: "Harness AWS connector using OIDC"
execute_on_delegate: true
force_delete: false
tags:
  owner: platform-team

oidc_authentication:
  iam_role_arn: "arn:aws:iam::123456789012:role/harness-oidc-role"
  region: "us-east-1"
  delegate_selectors:
    - "aws-delegate"

# Optional
# cross_account_access:
#   role_arn: "arn:aws:iam::210987654321:role/target-role"
#   external_id: "optional-external-id"
```

Notes:

- Connector identifier is derived from the filename in repo wiring (consistent with other connector patterns).
- Do not store AWS access keys in config; use OIDC (or Harness secret refs if using manual auth).

## Outputs

- `connector_id`
- `connector_identifier`
- `connector_name`

## Validation Notes

The resource schema used by this module (`harness_platform_connector_aws`) was checked via Terraform MCP against the current `harness/harness` provider docs, including:

- `oidc_authentication { iam_role_arn, delegate_selectors, region }`
- optional `org_id` / `project_id` scope inputs
- optional `cross_account_access`

## References (Official Harness Docs)

- Add an AWS connector: https://developer.harness.io/docs/platform/connectors/cloud-providers/ref-cloud-providers/aws-connector-settings-reference/
- Connect to AWS with OIDC: https://developer.harness.io/docs/platform/connectors/cloud-providers/connect-to-aws-with-oidc/
- Harness delegate overview (delegate selection/runtime context): https://developer.harness.io/docs/platform/delegates/delegate-concepts/delegate-overview/

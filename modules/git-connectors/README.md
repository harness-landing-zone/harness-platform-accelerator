# Harness Platform GitHub Connector Module

This Terraform module automates the creation and management of **GitHub Connectors** within the Harness Platform. It supports various authentication methods, including HTTP (Username/Token), SSH, and GitHub Apps, and can be scoped at the Account, Organization, or Project level.

## Features

* **Flexible Auth:** Supports GitHub App, Personal Access Token (PAT), and SSH Key authentication.
* **Dynamic Scoping:** Deploy at Project, Org, or Account levels based on provided IDs.
* **API Access:** Built-in support for `api_authentication` blocks required for Harness "Git Experience," triggers, and status updates.
* **Smart Identifiers:** Automatically generates a clean identifier from the connector name if one isn't provided.
* **Extensible:** Designed to eventually support multiple connector types (Bitbucket, GitLab, etc.) via the `connector_type` logic.


## Usage

The following example demonstrates how to deploy a GitHub Connector using **GitHub App** authentication at a specific Project scope.

```hcl
locals {
  required_tags = {
    created_by = "Terraform"
    purpose    = "buildfarm"
  }

  # Format for Harness Platform (key:value strings)
  common_tags_list = [for k, v in local.required_tags : "${k}:${v}"]
}

module "github_connector" {
  source                = "git::https://github.com/your-repo/terraform-harness-connector.git"
  
  connector_type        = "github"
  connector_name        = "my-github-app-connector"
  connector_description = "Managed by Terraform"
  connector_tags        = local.common_tags_list
  
  # Scoping
  org_id                = "my-org"
  project_id            = "my-project"

  # Configuration
  git_connector_url     = "https://github.com/my-org"
  connection_type       = "Account"
  validation_repo       = "my-test-repo"

  # Authentication via GitHub App
  git_connector_http_credentials = {
    github_app = {
      application_id  = "123456"
      installation_id = "7891011"
      private_key_ref = "account.github_app_private_key"
    }
  }
}

```

---

## Requirements

| Name | Version |
| --- | --- |
| **Terraform** | >= 1.0.0 |
| **Harness Provider** | >= 0.14.0 |


## Inputs

### Generic Configuration

| Name | Description | Type | Default |
| --- | --- | --- | --- |
| `connector_type` | Type of connector (currently supports `github`). | `string` | **Required** |
| `connector_name` | The display name of the connector. | `string` | **Required** |
| `connector_identifier` | Unique ID. If omitted, the name is sanitized and used. | `string` | `""` |
| `project_id` | Harness Project ID. Omit for Account level. | `string` | `null` |
| `org_id` | Harness Org ID. Omit for Account level. | `string` | `null` |

### GitHub Specifics

| Name | Description | Type | Default |
| --- | --- | --- | --- |
| `git_connector_url` | URL of the Git repo or account. | `string` | `""` |
| `connection_type` | `Account` or `Repo`. | `string` | `"Account"` |
| `execute_on_delegate` | Whether to run connection through a delegate. | `bool` | `false` |
| `delegate_selectors` | Tags to select specific delegates. | `set(string)` | `[]` |

### Authentication Blocks

| Name | Description | Type | Default |
| --- | --- | --- | --- |
| `git_connector_http_credentials` | Object for HTTP/App auth. | `object` | `null` |
| `git_connector_ssh_credentials` | Object for SSH key auth. | `object` | `null` |
| `git_connector_api_auth` | Required for Git Experience/Triggers. | `object` | `null` |


## Outputs

| Name | Description |
| --- | --- |
| `identifier` | The unique identifier of the created connector. |
| `name` | The name of the created connector. |

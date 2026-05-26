variable "harness_platform_url" {
  type        = string
  description = "[Optional] Harness Platform URL. Defaults to Harness SaaS."
  default     = "https://app.harness.io/gateway"
}

variable "harness_platform_account" {
  type        = string
  description = "[Required] Harness Platform Account ID."
}

variable "tags" {
  type        = map(any)
  description = "[Optional] Additional tags to apply to all resources."
  default     = {}
}

variable "organization_name" {
  type        = string
  description = "[Required] Organization folder/name to target. Used for org creation and for resolving project config."
  default     = "Platform Management"
}

variable "organization_id" {
  type        = string
  description = "[Optional] Explicit organization identifier override. If omitted, the deployment root resolves it from config.yaml or from the normalized organization name."
  default     = null
}

variable "project_name" {
  type        = string
  description = "[Optional] Project display name to create under the organization."
  default     = null

  validation {
    condition     = var.project_name != null || var.scope_level != "project" || var.project_key != null
    error_message = "When scope_level is project, project_name or project_key must be set."
  }
}

variable "project_key" {
  type        = string
  description = "[Optional] Project folder key when it differs from the project display name."
  default     = null
}

variable "project_id" {
  type        = string
  description = "[Optional] Explicit project identifier override. If omitted, the deployment root resolves it from config.yaml or from the normalized project name."
  default     = null
}

variable "organization_description" {
  type        = string
  description = "[Optional] Organization description."
  default     = "Harness Organization managed by Solutions Factory"
}

variable "project_description" {
  type        = string
  description = "[Optional] Project description."
  default     = "Harness Project managed by Solutions Factory"
}

variable "scope_level" {
  type        = string
  description = "[Optional] Deployment scope: account (platform team only — account-level resources), organization (org + all discovered projects), or project (single project into existing org)."
  default     = "organization"

  validation {
    condition     = contains(["account", "organization", "project"], var.scope_level)
    error_message = "scope_level must be account, organization, or project."
  }
}

variable "git_connector_credentials" {
  type = map(object({
    http_credentials = optional(any, null)
    ssh_credentials  = optional(any, null)
    api_auth         = optional(any, null)
  }))
  sensitive   = true
  description = "[Optional] Credentials for git connectors keyed by connector identifier. Use terraform.tfvars (gitignored) instead of embedding credentials in YAML. Takes effect only when the connector YAML does not define the credential block."
  default     = {}
}

variable "configs_relative_path" {
  type        = string
  description = "Relative path to the platform-configs directory from this module. This is used to resolve the organization configuration files, independent of the current working directory."
  default     = "../platform-configs"
}

variable "platform_configs_repo_name" {
  type        = string
  description = "Name of the platform-configs repository."
  default     = "local-repo"
}

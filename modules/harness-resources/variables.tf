##############################################################################
# Platform connection
##############################################################################

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
  description = "[Optional] Map of tags to associate with all resources."
  default     = {}
}

##############################################################################
# Organization
# Set organization_name to target org scope.
# Leave null for account scope.
##############################################################################

variable "organization_name" {
  type        = string
  description = "[Optional] Organization display name. Setting this targets organization scope. Omit for account scope."
  default     = null
}

variable "organization_id" {
  type        = string
  description = "[Optional] Explicit organization identifier. Derived from organization_name when null."
  default     = null
}

variable "organization_description" {
  type        = string
  description = "[Optional] Organization description."
  default     = "Harness Organization managed by Solutions Factory"
}

variable "templates_root" {
  type        = string
  description = "[Optional] Absolute path used as the root when resolving template subfolders. Defaults to this module's own directory, allowing callers to supply their own default config trees."
  default     = null
}

variable "default_account_template" {
  type        = string
  description = "[Optional] Template subfolder to use as global defaults for account-scoped resources."
  default     = "templates"
}

variable "default_org_template" {
  type        = string
  description = "[Optional] Template subfolder to use as global defaults for org-scoped resources."
  default     = "org-default-config"
}

##############################################################################
# Project
# Set project_name (and organization_name) to target project scope.
# Leave null for account or organization scope.
##############################################################################

variable "project_name" {
  type        = string
  description = "[Optional] Project display name. Setting this (along with organization_name) targets project scope."
  default     = null
}

variable "project_id" {
  type        = string
  description = "[Optional] Explicit project identifier. Derived from project_name when null."
  default     = null
}

variable "project_description" {
  type        = string
  description = "[Optional] Project description."
  default     = "Harness Project managed by Solutions Factory"
}

variable "default_project_template" {
  type        = string
  description = "[Optional] Template subfolder to use as global defaults for project-scoped resources."
  default     = "project-default-config"
}

# project_key is the folder name under organizations/<org>/projects/<key>/.
# When calling this module directly for a standalone project it can be left
# null and the module derives it from project_name.  The org-scope recursive
# call sets it explicitly to the config folder name.
variable "project_key" {
  type        = string
  description = "[Optional] Config folder key for the project. Defaults to project_name."
  default     = null
}

##############################################################################
# Path resolution
# configs_relative_path is used for top-level entrypoint calls.
# configs_root and org_root are absolute paths set by the org-scope recursive
# call into this module for each discovered project — they take precedence.
##############################################################################

variable "configs_relative_path" {
  type        = string
  description = "[Optional] Relative path from this module to the platform-configs root. Used when configs_root is not set."
  default     = "../platform-configs"
}

variable "configs_root" {
  type        = string
  description = "[Optional] Absolute path to the platform-configs root. Overrides configs_relative_path when set."
  default     = null
}

variable "org_root" {
  type        = string
  description = "[Optional] Absolute path to the org config directory. Overrides computed path when set (used by recursive project calls)."
  default     = null
}

##############################################################################
# Secrets
##############################################################################

variable "pem_path" {
  type        = string
  description = "[Optional] Absolute path to the directory containing PEM files for file-type secrets."
  default     = null
}

variable "secret_values" {
  type        = map(string)
  sensitive   = true
  description = "[Optional] Map of secret identifier → plaintext value for text secrets defined in secrets/ YAML files."
  default     = {}
}

variable "git_connector_credentials" {
  type = map(object({
    http_credentials = optional(any, null)
    ssh_credentials  = optional(any, null)
    api_auth         = optional(any, null)
  }))
  sensitive   = true
  description = "[Optional] Credentials for git connectors keyed by connector identifier. Takes effect only when the connector YAML does not define the credential block."
  default     = {}
}

variable "platform_configs_repo_name" {
  type        = string
  description = "Name of the platform-configs repository."
  default     = "local-repo"
}
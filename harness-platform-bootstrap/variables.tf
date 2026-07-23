variable "harness_platform_url" {
  type        = string
  description = "[Optional] Harness Platform URL. Defaults to Harness SaaS."
  default     = "https://app.harness.io/gateway"
}

variable "harness_platform_account" {
  type        = string
  description = "[Required] Harness Platform Account ID."
  default = "9iW-060ARf-7xLCnVrVJbQ"
}

variable "tags" {
  type        = map(any)
  description = "[Optional] Additional tags to apply to all resources."
  default     = {}
}

variable "organization_name" {
  type        = string
  description = "[Required] New Organization Name"
  default     = "Platform Management"
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

variable "scope_level" {
  type        = string
  description = "[Optional] Deployment scope: account (platform team only — account-level resources), organization (org + all discovered projects), or project (single project into existing org)."
  default     = "organization"

  validation {
    condition     = contains(["account", "organization", "project"], var.scope_level)
    error_message = "scope_level must be account, organization, or project."
  }
}

variable "prefix" {
  type        = string
  default     = ""
  description = "Resource prefix to ensure uniqueness. Should be left blank when deploying a single instance of the module, but can be set to differentiate resources when deploying multiple instances (e.g. across environments)."
}
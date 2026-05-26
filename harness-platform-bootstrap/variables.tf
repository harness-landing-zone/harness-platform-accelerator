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
  description = "[Required] New Organization Name"
  default     = "Platform Management"
}

variable "gcs_bucket" {
  type        = string
  description = "[Required] GCS bucket name for tofu remote state storage."
}

variable "gcp_project" {
  type        = string
  description = "[Required] GCP project ID used for OIDC token exchange and GCS backend."
}

variable "gcp_pool_id" {
  type        = string
  description = "[Required] GCP Workload Identity Pool ID for OIDC authentication."
}

variable "gcp_provider_id" {
  type        = string
  description = "[Required] GCP Workload Identity Provider ID for OIDC authentication."
}

variable "gcp_service_account_email" {
  type        = string
  description = "[Required] GCP service account email for OIDC token exchange."
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
variable "harness_platform_url" {
  type        = string
  description = "[Optional] Harness Platform URL. Defaults to Harness SaaS."
  default     = "https://app.harness.io/gateway"
}

variable "harness_platform_account" {
  type        = string
  description = "[Required] Harness Platform Account ID. Supply per environment via terraform.tfvars (gitignored) or the HARNESS_ACCOUNT_ID env var — do not commit a real account ID."
}

variable "tags" {
  type        = map(any)
  description = "[Optional] Additional tags to apply to all resources."
  default     = {}
}

variable "organization_name" {
  type        = string
  description = "[Required] Organization name — must match the config-folder name under organizations/. Selects which org config tree to deploy; the org display name and identifier come from that folder's config.yaml (this value is the fallback when config.yaml omits them)."
  default     = "harness-platform-accelerator"
}

# GCP/GCS settings are consumed only by the deploy pipeline (for `tofu init
# -backend-config` and OIDC token exchange) — no resource in this module
# references them. They default to empty so a local/stateless run requires
# neither a GCS backend nor GCP credentials. The pipeline overrides them via
# TF_VAR_* when the GCS backend is in use.

variable "gcs_bucket" {
  type        = string
  description = "[Optional] GCS bucket name for tofu remote state storage. Only needed when using the GCS backend via the deploy pipeline."
  default     = ""
}

variable "gcp_project" {
  type        = string
  description = "[Optional] GCP project ID used for OIDC token exchange and GCS backend."
  default     = ""
}

variable "gcp_pool_id" {
  type        = string
  description = "[Optional] GCP Workload Identity Pool ID for OIDC authentication."
  default     = ""
}

variable "gcp_provider_id" {
  type        = string
  description = "[Optional] GCP Workload Identity Provider ID for OIDC authentication."
  default     = ""
}

variable "gcp_service_account_email" {
  type        = string
  description = "[Optional] GCP service account email for OIDC token exchange."
  default     = ""
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
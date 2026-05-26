# ── Provider ──────────────────────────────────────────────────────────────
terraform {
  required_providers {
    harness = {
      source  = "harness/harness"
      version = ">= 0.40"
    }
  }
}

# provider "harness" {
#   # HARNESS_ENDPOINT must be set explicitly — do NOT rely on default
#   # app.harness.io/gateway. The pipeline passes it via env var.
#   endpoint = var.harness_platform_url
# }

# ── Core variables (passed from pipeline) ─────────────────────────────────
variable "harness_platform_account" {
  type        = string
  description = "Harness account identifier"
}

variable "harness_platform_url" {
  type        = string
  description = "Harness Platform API endpoint"
  default     = "https://app.harness.io/gateway"
}

variable "organization_name" {
  type        = string
  description = "Target organization name"
  default     = null
}

variable "organization_id" {
  type        = string
  description = "Explicit organization identifier override"
  default     = null
}

variable "project_name" {
  type        = string
  description = "Target project name (only for scope_level = project)"
  default     = null
}

variable "project_id" {
  type        = string
  description = "Explicit project identifier override"
  default     = null
}

variable "scope_level" {
  type        = string
  description = "Deployment scope: account, organization, or project"
  default     = "organization"

  validation {
    condition     = contains(["account", "organization", "project"], var.scope_level)
    error_message = "scope_level must be account, organization, or project."
  }
}

variable "project_key" {
  type        = string
  description = "Project folder key when it differs from the project display name"
  default     = null
}

variable "organization_description" {
  type        = string
  description = "Organization description"
  default     = "Harness Organization managed by Solutions Factory"
}

variable "project_description" {
  type        = string
  description = "Project description"
  default     = "Harness Project managed by Solutions Factory"
}

variable "configs_relative_path" {
  type        = string
  description = "Relative path to the platform-configs directory from the deployment module"
  default     = "../platform-configs"
}

variable "platform_configs_repo_name" {
  type    = string
  default = "local-repo"
}

# ── Shared local (same logic as harness-platform-deployment) ───────────────
locals {
  org_identifier = (
    var.organization_id != null ? var.organization_id :
    var.organization_name != null ? replace(replace(var.organization_name, " ", "_"), "-", "_") :
    ""
  )
}
variable "connector_type" {
  description = "Secret manager type for the connector. Supported values: vault."
  type        = string
  default     = "vault"

  validation {
    condition     = contains(["vault"], var.connector_type)
    error_message = "connector_type must be one of: vault."
  }
}

variable "connector_name" {
  description = "Name of the connector."
  type        = string
}

variable "connector_identifier" {
  description = "Unique identifier of the connector."
  type        = string
  default     = null
  nullable    = true
}

variable "connector_description" {
  description = "Description of the resource."
  type        = string
  default     = null
  nullable    = true
}

variable "connector_tags" {
  description = "Tags to associate with the resource."
  type        = set(string)
  default     = []
}

variable "org_id" {
  description = "Unique identifier of the organization."
  type        = string
  default     = null
  nullable    = true
}

variable "project_id" {
  description = "Unique identifier of the project."
  type        = string
  default     = null
  nullable    = true
}

variable "execute_on_delegate" {
  description = "Execute on delegate or not."
  type        = bool
  default     = false
}

# ── Vault ─────────────────────────────────────────────────────────────────────

variable "vault_url" {
  description = "URL of the HashiCorp Vault server."
  type        = string
}

variable "base_path" {
  description = "Location of the KV secrets engine within Vault."
  type        = string
  default     = null
  nullable    = true
}

variable "namespace" {
  description = "Vault namespace (Vault Enterprise)."
  type        = string
  default     = null
  nullable    = true
}

variable "secret_engine_name" {
  description = "Name of the Vault secret engine."
  type        = string
  default     = null
  nullable    = true
}

variable "secret_engine_version" {
  description = "Version of the Vault secret engine (1 or 2)."
  type        = number
  default     = null
  nullable    = true
}

variable "renewal_interval_minutes" {
  description = "Time interval (minutes) for token renewal."
  type        = number
  default     = 10
}

variable "is_default" {
  description = "Make this the default secret manager for the scope."
  type        = bool
  default     = false
}

variable "is_read_only" {
  description = "Treat the Vault secret manager as read only."
  type        = bool
  default     = false
}

variable "delegate_selectors" {
  description = "Delegate selectors used to connect to Vault."
  type        = set(string)
  default     = null
  nullable    = true
}

# ── Authentication ──────────────────────────────────────────────────────────

variable "jwt_authentication" {
  description = "OIDC authentication via Vault's JWT/OIDC auth method. auth_token is a Harness secret reference holding the JWT."
  type = object({
    auth_token          = string
    vault_jwt_auth_path = optional(string)
    vault_jwt_auth_role = optional(string)
  })
  default = null

  validation {
    condition     = var.jwt_authentication == null || trimspace(var.jwt_authentication.auth_token) != ""
    error_message = "jwt_authentication.auth_token must be set when OIDC (JWT) authentication is used."
  }
}

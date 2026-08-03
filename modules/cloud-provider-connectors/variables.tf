variable "connector_type" {
  description = "Cloud provider type for the connector. Supported values: aws, gcp, kubernetes."
  type        = string
  default     = "aws"

  validation {
    condition     = contains(["aws", "gcp", "kubernetes"], var.connector_type)
    error_message = "connector_type must be one of: aws, gcp, kubernetes."
  }
}

variable "delegate_selectors" {
  description = "Delegate selectors for the connector (used by kubernetes)."
  type        = set(string)
  default     = []
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

variable "force_delete" {
  description = "Enable this flag for force deletion of connector"
  type        = bool
  default     = false
}

# ── AWS Authentication ────────────────────────────────────────────────────────

variable "aws_connector_inherit_from_delegate" {
  description = "Authentication using harness delegate."
  type = object({
    delegate_selectors = set(string)
    region             = optional(string)
  })
  default = null
}

variable "aws_connector_manual_authentication" {
  description = "Authentication using static AWS access/secret keys."
  type = object({
    access_key_ref     = string
    secret_key_ref     = string
    delegate_selectors = set(string)
    region             = optional(string)
  })
  default = null
}

variable "aws_connector_irsa_authentication" {
  description = "IRSA authentication for AWS connector."
  type = object({
    delegate_selectors = set(string)
    region             = optional(string)
  })
  default = null
}

variable "aws_connector_oidc_authentication" {
  description = "OIDC authentication for AWS connector."
  type = object({
    iam_role_arn       = string
    delegate_selectors = optional(set(string), [])
    region             = optional(string)
  })
  default = null

  validation {
    condition     = var.aws_connector_oidc_authentication == null || trimspace(var.aws_connector_oidc_authentication.iam_role_arn) != ""
    error_message = "aws_connector_oidc_authentication.iam_role_arn must be set when OIDC authentication is used."
  }
}

variable "aws_connector_cross_account_access" {
  description = "Use cross account access for delegation."
  type = object({
    role_arn    = string
    external_id = optional(string, "")
  })
  default = null
}

variable "aws_connector_equal_jitter_backoff_strategy" {
  description = "Equal jitter backoff strategy."
  type = object({
    base_delay       = optional(number, null)
    max_backoff_time = optional(number, null)
    retry_count      = optional(number, null)
  })
  default = null
}

variable "aws_connector_fixed_delay_backoff_strategy" {
  description = "Fixed delay backoff strategy."
  type = object({
    fixed_backoff = optional(number, null)
    retry_count   = optional(number, null)
  })
  default = null
}

variable "aws_connector_full_jitter_backoff_strategy" {
  description = "Full jitter backoff strategy."
  type = object({
    base_delay       = optional(number, null)
    max_backoff_time = optional(number, null)
    retry_count      = optional(number, null)
  })
  default = null
}

# ── GCP Authentication ────────────────────────────────────────────────────────

variable "gcp_connector_oidc_authentication" {
  description = "Workload Identity Federation (OIDC) authentication for GCP connector."
  type = object({
    workload_pool_id      = string
    provider_id           = string
    gcp_project_id        = string
    service_account_email = string
    delegate_selectors    = optional(set(string), [])
  })
  default = null
}

variable "gcp_connector_manual_authentication" {
  description = "Manual authentication using a GCP service account key secret."
  type = object({
    secret_key_ref     = string
    delegate_selectors = optional(set(string), [])
  })
  default = null
}

variable "gcp_connector_inherit_from_delegate" {
  description = "Authentication inherited from the Harness delegate running on GCP."
  type = object({
    delegate_selectors = set(string)
  })
  default = null
}

# ── Kubernetes Authentication ─────────────────────────────────────────────────

variable "k8s_connector_inherit_from_delegate" {
  description = "Kubernetes auth inherited from a Harness delegate running in-cluster."
  type = object({
    delegate_selectors = set(string)
  })
  default = null
}

variable "k8s_connector_username_password" {
  description = "Kubernetes auth using username/password against the API server."
  type = object({
    master_url   = string
    password_ref = string
    username     = optional(string)
    username_ref = optional(string)
  })
  default = null
}

variable "k8s_connector_service_account" {
  description = "Kubernetes auth using a service account token."
  type = object({
    master_url                = string
    service_account_token_ref = string
    ca_cert_ref               = optional(string)
  })
  default = null
}

variable "k8s_connector_client_key_cert" {
  description = "Kubernetes auth using a client key and certificate."
  type = object({
    master_url                = string
    client_cert_ref           = string
    client_key_ref            = string
    client_key_algorithm      = string
    ca_cert_ref               = optional(string)
    client_key_passphrase_ref = optional(string)
  })
  default = null
}

variable "k8s_connector_openid_connect" {
  description = "Kubernetes auth using OpenID Connect."
  type = object({
    master_url    = string
    issuer_url    = string
    client_id_ref = string
    password_ref  = string
    username      = optional(string)
    username_ref  = optional(string)
    secret_ref    = optional(string)
    scopes        = optional(list(string))
  })
  default = null
}

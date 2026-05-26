# Harness IACM Workspaces
variable "workspace_name" {
  description = "Name of the workspace."
  type        = string
}

variable "workspace_identifier" {
  description = "Unique identifier of the workspace."
  type        = string
  default     = null
  nullable    = true
}

variable "workspace_description" {
  description = "Description of the workspace."
  type        = string
  default     = null
  nullable    = true
}

variable "workspace_tags" {
  description = "Tags to associate with the workspace."
  type        = set(string)
  default     = []
}

variable "org_id" {
  description = "Unique identifier of the organization."
  type        = string

  validation {
    condition     = trimspace(var.org_id) != ""
    error_message = "org_id must not be empty."
  }
}

variable "project_id" {
  description = "Unique identifier of the project."
  type        = string

  validation {
    condition     = trimspace(var.project_id) != ""
    error_message = "project_id must not be empty."
  }
}

variable "cost_estimation_enabled" {
  description = "Enable cost estimation for the workspace."
  type        = bool
}

variable "provisioner_type" {
  description = "Provisioner type to use. Valid values are terraform or opentofu."
  type        = string

  validation {
    condition     = contains(["terraform", "opentofu"], var.provisioner_type)
    error_message = "provisioner_type must be one of: terraform, opentofu."
  }
}

variable "provisioner_version" {
  description = "Provisioner version used by the workspace."
  type        = string
}

variable "repository" {
  description = "Repository URL/name to fetch workspace code from."
  type        = string
}

variable "repository_connector" {
  description = "Harness connector reference used to fetch the workspace code."
  type        = string
}

variable "repository_path" {
  description = "Path in the repository where the workspace code resides."
  type        = string
}

variable "repository_branch" {
  description = "Branch to fetch the workspace code from. Exactly one of repository_branch, repository_commit, or repository_sha must be set."
  type        = string
  default     = null
  nullable    = true
}

variable "repository_commit" {
  description = "Tag/commit label to fetch the workspace code from. Exactly one of repository_branch, repository_commit, or repository_sha must be set."
  type        = string
  default     = null
  nullable    = true
}

variable "repository_sha" {
  description = "Commit SHA to fetch the workspace code from. Exactly one of repository_branch, repository_commit, or repository_sha must be set."
  type        = string
  default     = null
  nullable    = true
}

variable "provider_connector" {
  description = "Provider connector reference for the infrastructure provider (deprecated in provider docs; prefer workspace_connectors)."
  type        = string
  default     = null
  nullable    = true
}

variable "workspace_connectors" {
  description = "Provider connectors configured on the workspace. Only one connector per type is supported."
  type = list(object({
    connector_ref = string
    type          = string
  }))
  default = []

  validation {
    condition = alltrue([
      for connector in var.workspace_connectors : contains(["aws", "azure", "gcp"], connector.type)
    ])
    error_message = "workspace_connectors[*].type must be one of: aws, azure, gcp."
  }
}

variable "terraform_variables" {
  description = "Terraform variables configured on the workspace."
  type = list(object({
    key        = string
    value      = string
    value_type = string
  }))
  default = []

  validation {
    condition = alltrue([
      for variable in var.terraform_variables : contains(["string", "secret"], variable.value_type)
    ])
    error_message = "terraform_variables[*].value_type must be one of: string, secret."
  }
}

variable "environment_variables" {
  description = "Environment variables configured on the workspace."
  type = list(object({
    key        = string
    value      = string
    value_type = string
  }))
  default = []

  validation {
    condition = alltrue([
      for variable in var.environment_variables : contains(["string", "secret"], variable.value_type)
    ])
    error_message = "environment_variables[*].value_type must be one of: string, secret."
  }
}

variable "terraform_variable_files" {
  description = "Terraform variable files configured on the workspace."
  type = list(object({
    repository           = string
    repository_connector = string
    repository_path      = optional(string)
    repository_branch    = optional(string)
    repository_commit    = optional(string)
    repository_sha       = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for tfvars_file in var.terraform_variable_files :
      (
        (try(tfvars_file.repository_branch, null) != null && trimspace(try(tfvars_file.repository_branch, "")) != "" ? 1 : 0) +
        (try(tfvars_file.repository_commit, null) != null && trimspace(try(tfvars_file.repository_commit, "")) != "" ? 1 : 0) +
        (try(tfvars_file.repository_sha, null) != null && trimspace(try(tfvars_file.repository_sha, "")) != "" ? 1 : 0)
      ) <= 1
    ])
    error_message = "Each terraform_variable_files entry can set at most one of repository_branch, repository_commit, repository_sha."
  }
}

variable "variable_sets" {
  description = "List of Harness variable set references to attach to the workspace."
  type        = list(string)
  default     = []
}

variable "default_pipelines" {
  description = "Map of default pipeline identifiers for workspace operations."
  type        = map(string)
  default     = {}
}

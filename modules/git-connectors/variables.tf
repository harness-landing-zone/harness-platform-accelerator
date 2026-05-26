# Git Connectors Generic
variable "connector_type" {
  description = "Name of the connector."
  type        = string
}

variable "connector_name" {
  description = "Name of the connector."
  type        = string
}

variable "connector_identifier" {
  description = "Unique identifier of the connector."
  type        = string
  default     = ""
}

variable "connector_description" {
  description = "Description of the resource."
  type        = string
  default     = ""
}

variable "connector_tags" {
  description = "Tags to associate with the resource."
  type        = set(string)
  default     = []
}

variable "git_connector_url" {
  description = "URL of the Git repository or account."
  type        = string
  default     = ""
}

variable "connection_type" {
  description = "Whether the connection we're making is to a github repository or a github account. Valid values are Account, Repo."
  type        = string
  default     = "Account"
}

variable "deployment_scope" {
  description = "The deployment scope of the connector that can be account/org/project"
  type        = string
  default     = "Account"
}

variable "validation_repo" {
  description = "Repository to test the connection with. This is only used when connection_type is set to 'Account'."
  type        = string
  default     = ""
}

variable "execute_on_delegate" {
  description = "Execute on delegate or not."
  type        = bool
  default     = false
}

variable "delegate_selectors" {
  description = "Tags to filter delegates for connection."
  type        = set(string)
  default     = []
}

# Git connector variables
variable "git_connector_http_credentials" {
  description = "HTTP credentials for the Git connector."
  type = object({
    username_ref = optional(string)
    token_ref    = optional(string)
    username     = optional(string)
    password_ref = optional(string)
    github_app = optional(object({
      application_id      = optional(string)
      application_id_ref  = optional(string)
      installation_id     = optional(string)
      installation_id_ref = optional(string)
      private_key_ref     = optional(string)
    }))
  })
  default = null
}

variable "git_connector_ssh_credentials" {
  description = "SSH credentials for the Git connector."
  type = object({
    ssh_key_ref = optional(string)
  })
  default = null
}

variable "git_connector_api_auth" {
  description = "Configuration for using the git api. API Access is required for using “Git Experience”, for creation of Git based triggers, Webhooks management and updating Git statuses."
  type = object({
    token_ref      = optional(string)
    github_app_api = optional(bool)
  })
  default = null
}

variable "force_delete" {
  description = "Enable this flag for force deletion of connector"
  type        = bool
  default     = false
}

variable "project_id" {
  description = "Unique identifier of the project. Omit for Account level."
  type        = string
  default     = null
}

variable "org_id" {
  description = "Unique identifier of the organization. Omit for Account level."
  type        = string
  default     = null
}
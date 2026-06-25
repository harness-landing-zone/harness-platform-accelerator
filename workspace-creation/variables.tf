variable "workspace_repository" {
  type    = string
  description = "The Default repository for the IACM workspace to closne the code"
  default = "harness-platform-accelerator"
}

variable "workspace_repository_connector" {
  type    = string
  description = "Default connector example"
  default = "org.platform_configs"
}

variable "workspace_repository_path" {
  type    = string
  description = "Repository path for code deployment"
  default = "harness-platform-deployment"
}

variable "workspace_repository_branch" {
  type    = string
  description = "Repository branch"
  default = "main"
}

variable "workspace_provisioner_version" {
  type    = string
  description = "Tofu Version of the workspace"
  default = "1.11.0"
}

variable "workspace_api_key_secret_ref" {
  type    = string
  description = "The API key to be used to deploy the environment"
  default = "account.harness_bootstrap_api_key"
}

variable "workspace_org_id" {
  type    = string
  description = "Organisasion that we deploy the workspace"
  default = "harness_platform_accelerator"
}

variable "workspace_project_id" {
  type    = string
  description = "Project we deploy the workspace"
  default = "platform_management"
}

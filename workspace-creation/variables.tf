variable "workspace_repository" {
  type    = string
  default = "hsf-custom-harness-template-library"
}

variable "workspace_repository_connector" {
  type    = string
  default = "org.platform_configs"
}

variable "workspace_repository_path" {
  type    = string
  default = "harness-platform-deployment"
}

variable "workspace_repository_branch" {
  type    = string
  default = "tofu"
}

variable "workspace_provisioner_version" {
  type    = string
  default = "1.11.0"
}

variable "workspace_api_key_secret_ref" {
  type    = string
  default = "account.harness_bootstrap_api_key"
}

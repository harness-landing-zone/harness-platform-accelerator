resource "harness_platform_workspace" "workspace" {
  name = var.workspace_name
  identifier = (
    var.workspace_identifier != null && trimspace(var.workspace_identifier) != ""
    ? var.workspace_identifier
    : replace(replace(lower(var.workspace_name), " ", "_"), "-", "_")
  )
  description = (
    var.workspace_description != null && trimspace(var.workspace_description) != ""
    ? var.workspace_description
    : null
  )
  tags = toset(try(var.workspace_tags, []))

  org_id     = var.org_id
  project_id = var.project_id

  cost_estimation_enabled = var.cost_estimation_enabled
  provisioner_type        = var.provisioner_type
  provisioner_version     = var.provisioner_version
  repository              = var.repository
  repository_connector    = var.repository_connector
  repository_path         = var.repository_path
  repository_branch = (
    var.repository_branch != null && trimspace(var.repository_branch) != ""
    ? var.repository_branch
    : null
  )
  repository_commit = (
    var.repository_commit != null && trimspace(var.repository_commit) != ""
    ? var.repository_commit
    : null
  )
  repository_sha = (
    var.repository_sha != null && trimspace(var.repository_sha) != ""
    ? var.repository_sha
    : null
  )
  provider_connector = (
    var.provider_connector != null && trimspace(var.provider_connector) != ""
    ? var.provider_connector
    : null
  )
  variable_sets     = try(var.variable_sets, [])
  default_pipelines = length(var.default_pipelines) > 0 ? var.default_pipelines : null

  dynamic "connector" {
    for_each = {
      for connector in var.workspace_connectors :
      "${connector.type}:${connector.connector_ref}" => connector
    }
    content {
      connector_ref = connector.value.connector_ref
      type          = connector.value.type
    }
  }

  dynamic "terraform_variable" {
    for_each = {
      for variable in var.terraform_variables : variable.key => variable
    }
    content {
      key        = terraform_variable.value.key
      value      = terraform_variable.value.value
      value_type = terraform_variable.value.value_type
    }
  }

  dynamic "environment_variable" {
    for_each = {
      for variable in var.environment_variables : variable.key => variable
    }
    content {
      key        = environment_variable.value.key
      value      = environment_variable.value.value
      value_type = environment_variable.value.value_type
    }
  }

  dynamic "terraform_variable_file" {
    for_each = {
      for tfvars_file in var.terraform_variable_files :
      "${tfvars_file.repository}|${tfvars_file.repository_connector}|${try(tfvars_file.repository_path, "")}|${try(tfvars_file.repository_branch, "")}|${try(tfvars_file.repository_commit, "")}|${try(tfvars_file.repository_sha, "")}" => tfvars_file
    }
    content {
      repository           = terraform_variable_file.value.repository
      repository_connector = terraform_variable_file.value.repository_connector
      repository_path      = try(terraform_variable_file.value.repository_path, null)
      repository_branch    = try(terraform_variable_file.value.repository_branch, null)
      repository_commit    = try(terraform_variable_file.value.repository_commit, null)
      repository_sha       = try(terraform_variable_file.value.repository_sha, null)
    }
  }

  lifecycle {
    precondition {
      condition = (
        (var.repository_branch != null && trimspace(var.repository_branch) != "" ? 1 : 0) +
        (var.repository_commit != null && trimspace(var.repository_commit) != "" ? 1 : 0) +
        (var.repository_sha != null && trimspace(var.repository_sha) != "" ? 1 : 0)
      ) == 1
      error_message = "Exactly one of repository_branch, repository_commit, repository_sha must be set."
    }

    precondition {
      condition = length(distinct([
        for connector in var.workspace_connectors : connector.type
      ])) == length(var.workspace_connectors)
      error_message = "Only one workspace_connectors entry per type is supported."
    }
  }
}

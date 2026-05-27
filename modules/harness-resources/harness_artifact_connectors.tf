# Artifact connectors for container registries and artifact repositories
# Supports Docker, ECR, GCR, ACR at account, organization, or project scope

locals {
  artifact_connectors = try(local.merged_sources["artifact-connectors"], {})

  # Separate by connector type
  docker_connectors = {
    for k, v in local.artifact_connectors :
    k => v
    if lower(lookup(v.cnf, "type", "")) == "docker"
  }

  ecr_connectors = {
    for k, v in local.artifact_connectors :
    k => v
    if lower(lookup(v.cnf, "type", "")) == "ecr"
  }

  gcr_connectors = {
    for k, v in local.artifact_connectors :
    k => v
    if lower(lookup(v.cnf, "type", "")) == "gcr"
  }

  acr_connectors = {
    for k, v in local.artifact_connectors :
    k => v
    if lower(lookup(v.cnf, "type", "")) == "acr"
  }
}

##############################################################################
# Docker Registry Connector
# Generic Docker registry connector (DockerHub, Harbor, Nexus, etc.)
##############################################################################

resource "harness_platform_connector_docker" "docker" {
  depends_on = [
    module.aws_cloud_provider_connector,
    module.gcp_cloud_provider_connector
  ]

  for_each = local.docker_connectors

  identifier  = each.value.identifier
  name        = each.value.name
  description = lookup(each.value.cnf, "description", "Harness Docker connector managed by Solutions Factory")
  org_id      = local.resolved_org_id
  project_id  = local.resolved_project_id

  tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])

  type = lookup(each.value.cnf, "docker_type", "DockerHub")  # DockerHub, Harbor, Other, Quay

  url = lookup(each.value.cnf, "url", "https://index.docker.io/v2/")

  # Delegate selectors (optional)
  delegate_selectors = try(each.value.cnf.delegate_selectors, [])

  # Execute on delegate (optional)
  execute_on_delegate = try(each.value.cnf.execute_on_delegate, null)

  # Authentication
  dynamic "credentials" {
    for_each = lookup(each.value.cnf, "credentials", null) != null ? [each.value.cnf.credentials] : []

    content {
      dynamic "username_password" {
        for_each = lookup(credentials.value, "username_password", null) != null ? [credentials.value.username_password] : []

        content {
          username     = lookup(username_password.value, "username", null)
          username_ref = lookup(username_password.value, "username_ref", null)
          password_ref = username_password.value.password_ref
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition = contains([
        "DockerHub",
        "Harbor",
        "Other",
        "Quay"
      ], lookup(each.value.cnf, "docker_type", "DockerHub"))
      error_message = "Invalid docker_type. Must be one of: DockerHub, Harbor, Other, Quay."
    }
  }
}

##############################################################################
# AWS ECR Connector
# Amazon Elastic Container Registry
##############################################################################

resource "harness_platform_connector_docker" "ecr" {
  depends_on = [
    module.aws_cloud_provider_connector
  ]

  for_each = local.ecr_connectors

  identifier  = each.value.identifier
  name        = each.value.name
  description = lookup(each.value.cnf, "description", "Harness ECR connector managed by Solutions Factory")
  org_id      = local.resolved_org_id
  project_id  = local.resolved_project_id

  tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])

  type = "Aws"

  url = lookup(each.value.cnf, "url", null)  # ECR registry URL

  # Delegate selectors
  delegate_selectors = try(each.value.cnf.delegate_selectors, [])

  execute_on_delegate = try(each.value.cnf.execute_on_delegate, null)

  # AWS authentication
  dynamic "credentials" {
    for_each = lookup(each.value.cnf, "credentials", null) != null ? [each.value.cnf.credentials] : []

    content {
      dynamic "aws" {
        for_each = lookup(credentials.value, "aws", null) != null ? [credentials.value.aws] : []

        content {
          # Reference to AWS connector for authentication
          aws_connector_ref = aws.value.aws_connector_ref
          region            = lookup(aws.value, "region", null)
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = lookup(each.value.cnf, "credentials", null) != null
      error_message = "ECR connector requires credentials block with aws authentication."
    }
  }
}

##############################################################################
# GCP GCR/GAR Connector
# Google Container Registry / Google Artifact Registry
##############################################################################

resource "harness_platform_connector_docker" "gcr" {
  depends_on = [
    module.gcp_cloud_provider_connector
  ]

  for_each = local.gcr_connectors

  identifier  = each.value.identifier
  name        = each.value.name
  description = lookup(each.value.cnf, "description", "Harness GCR connector managed by Solutions Factory")
  org_id      = local.resolved_org_id
  project_id  = local.resolved_project_id

  tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])

  type = "Gcr"

  url = lookup(each.value.cnf, "url", null)  # GCR/GAR registry URL

  # Delegate selectors
  delegate_selectors = try(each.value.cnf.delegate_selectors, [])

  execute_on_delegate = try(each.value.cnf.execute_on_delegate, null)

  # GCP authentication
  dynamic "credentials" {
    for_each = lookup(each.value.cnf, "credentials", null) != null ? [each.value.cnf.credentials] : []

    content {
      dynamic "gcp" {
        for_each = lookup(credentials.value, "gcp", null) != null ? [credentials.value.gcp] : []

        content {
          # Reference to GCP connector for authentication
          gcp_connector_ref = gcp.value.gcp_connector_ref
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = lookup(each.value.cnf, "credentials", null) != null
      error_message = "GCR connector requires credentials block with gcp authentication."
    }
  }
}

##############################################################################
# Azure ACR Connector
# Azure Container Registry
##############################################################################

resource "harness_platform_connector_docker" "acr" {
  for_each = local.acr_connectors

  identifier  = each.value.identifier
  name        = each.value.name
  description = lookup(each.value.cnf, "description", "Harness ACR connector managed by Solutions Factory")
  org_id      = local.resolved_org_id
  project_id  = local.resolved_project_id

  tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])

  type = "Azure"

  url = lookup(each.value.cnf, "url", null)  # ACR registry URL

  # Delegate selectors
  delegate_selectors = try(each.value.cnf.delegate_selectors, [])

  execute_on_delegate = try(each.value.cnf.execute_on_delegate, null)

  # Azure authentication
  dynamic "credentials" {
    for_each = lookup(each.value.cnf, "credentials", null) != null ? [each.value.cnf.credentials] : []

    content {
      dynamic "azure" {
        for_each = lookup(credentials.value, "azure", null) != null ? [credentials.value.azure] : []

        content {
          # Reference to Azure connector for authentication
          azure_connector_ref = azure.value.azure_connector_ref
          subscription_id     = azure.value.subscription_id
          registry_name       = azure.value.registry_name
          resource_group      = azure.value.resource_group
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = lookup(each.value.cnf, "credentials", null) != null
      error_message = "ACR connector requires credentials block with azure authentication."
    }
  }
}

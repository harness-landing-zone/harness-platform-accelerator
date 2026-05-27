# Infrastructure definitions can be created at account, organization, or project scope.
# They define the deployment targets for Harness CD pipelines.

locals {
  infrastructures = try(local.merged_sources["infrastructures"], {})
}

##############################################################################
# Infrastructure Definitions
# Defines deployment targets (Kubernetes clusters, VMs, cloud platforms, etc.)
# Links to connectors and environments for CD pipeline execution.
##############################################################################

resource "harness_platform_infrastructure" "infrastructures" {
  depends_on = [
    module.git_connector,
    module.aws_cloud_provider_connector,
    module.gcp_cloud_provider_connector
  ]

  for_each = local.infrastructures

  identifier = each.value.identifier
  name       = each.value.name
  org_id     = local.resolved_org_id
  project_id = local.resolved_project_id

  # Environment reference - required for all infrastructure definitions
  env_id = lookup(each.value.cnf, "env_id", null)

  # Type of infrastructure - determines which block to use below
  type = lookup(each.value.cnf, "type", "KubernetesDirect")

  # Deployment template reference (optional)
  deployment_type = lookup(each.value.cnf, "deployment_type", "Kubernetes")

  description = lookup(each.value.cnf, "description", "Harness Infrastructure managed by Solutions Factory")

  tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])

  # YAML definition - contains the infrastructure spec
  # Different types require different YAML structures
  yaml = lookup(each.value.cnf, "yaml", null) != null ? (
    replace(
      yamlencode(each.value.cnf.yaml),
      "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/",
      "$1$2:"
    )
  ) : null

  force_delete = lookup(each.value.cnf, "force_delete", false)

  lifecycle {
    precondition {
      condition     = lookup(each.value.cnf, "env_id", null) != null
      error_message = "Infrastructure definition requires 'env_id' to link to an environment."
    }

    precondition {
      condition = contains([
        "KubernetesDirect",
        "KubernetesGcp",
        "KubernetesAzure",
        "KubernetesAws",
        "ServerlessAwsLambda",
        "AzureWebApp",
        "ECS",
        "GoogleCloudFunctions",
        "Ssh",
        "WinRm",
        "SshWinRmAzure",
        "SshWinRmAws",
        "PDC",
        "CustomDeployment",
        "TAS"
      ], lookup(each.value.cnf, "type", "KubernetesDirect"))
      error_message = "Invalid infrastructure type. Must be one of: KubernetesDirect, KubernetesGcp, KubernetesAzure, KubernetesAws, ServerlessAwsLambda, AzureWebApp, ECS, GoogleCloudFunctions, Ssh, WinRm, SshWinRmAzure, SshWinRmAws, PDC, CustomDeployment, TAS."
    }
  }
}

# Harness IDP Service Discovery Agents are project-scope only.

locals {
  service_discovery_agents = try(local.merged_sources["service-discovery-agents"], {})
}

resource "harness_service_discovery_agent" "service_discovery_agents" {
  depends_on = [harness_platform_environment.environments]

  for_each = local.scope == "project" ? local.service_discovery_agents : {}

  name                   = each.value.name
  org_identifier         = local.resolved_org_id
  project_identifier     = local.resolved_project_id
  environment_identifier = each.value.cnf.environment_identifier
  infra_identifier       = each.value.cnf.infra_identifier
  installation_type      = try(each.value.cnf.installation_type, null)
  permanent_installation = try(each.value.cnf.permanent_installation, null)
  webhook_url            = try(each.value.cnf.webhook_url, null)
  correlation_id         = try(each.value.cnf.correlation_id, null)

  config {
    collector_image    = try(each.value.cnf.config.collector_image, null)
    log_watcher_image  = try(each.value.cnf.config.log_watcher_image, null)
    skip_secure_verify = try(each.value.cnf.config.skip_secure_verify, null)
    image_pull_secrets = try(each.value.cnf.config.image_pull_secrets, null)

    kubernetes {
      namespace                  = each.value.cnf.config.kubernetes.namespace
      disable_namespace_creation = try(each.value.cnf.config.kubernetes.disable_namespace_creation, null)
      namespaced                 = try(each.value.cnf.config.kubernetes.namespaced, null)
      service_account            = try(each.value.cnf.config.kubernetes.service_account, null)
      run_as_user                = try(each.value.cnf.config.kubernetes.run_as_user, null)
      run_as_group               = try(each.value.cnf.config.kubernetes.run_as_group, null)
      image_pull_policy          = try(each.value.cnf.config.kubernetes.image_pull_policy, null)
      node_selector              = try(each.value.cnf.config.kubernetes.node_selector, null)
      labels                     = try(each.value.cnf.config.kubernetes.labels, null)
      annotations                = try(each.value.cnf.config.kubernetes.annotations, null)

      dynamic "tolerations" {
        for_each = try(each.value.cnf.config.kubernetes.tolerations, [])

        content {
          key                = tolerations.value.key
          operator           = tolerations.value.operator
          effect             = tolerations.value.effect
          value              = try(tolerations.value.value, null)
          toleration_seconds = try(tolerations.value.toleration_seconds, null)
        }
      }

      dynamic "resources" {
        for_each = try(each.value.cnf.config.kubernetes.resources, null) == null ? [] : [each.value.cnf.config.kubernetes.resources]

        content {
          dynamic "limits" {
            for_each = try(resources.value.limits, null) == null ? [] : [resources.value.limits]

            content {
              cpu    = try(limits.value.cpu, null)
              memory = try(limits.value.memory, null)
            }
          }

          dynamic "requests" {
            for_each = try(resources.value.requests, null) == null ? [] : [resources.value.requests]

            content {
              cpu    = try(requests.value.cpu, null)
              memory = try(requests.value.memory, null)
            }
          }
        }
      }
    }

    dynamic "data" {
      for_each = try(each.value.cnf.config.data, null) == null ? [] : [each.value.cnf.config.data]

      content {
        enable_node_agent        = try(data.value.enable_node_agent, null)
        node_agent_selector      = try(data.value.node_agent_selector, null)
        namespace_selector       = try(data.value.namespace_selector, null)
        enable_orphaned_pod      = try(data.value.enable_orphaned_pod, null)
        enable_batch_resources   = try(data.value.enable_batch_resources, null)
        collection_window_in_min = try(data.value.collection_window_in_min, null)
        blacklisted_namespaces   = try(data.value.blacklisted_namespaces, null)
        observed_namespaces      = try(data.value.observed_namespaces, null)

        dynamic "cron" {
          for_each = try(data.value.cron, null) == null ? [] : [data.value.cron]

          content {
            expression = try(cron.value.expression, null)
          }
        }
      }
    }

    dynamic "mtls" {
      for_each = try(each.value.cnf.config.mtls, null) == null ? [] : [each.value.cnf.config.mtls]

      content {
        cert_path   = try(mtls.value.cert_path, null)
        key_path    = try(mtls.value.key_path, null)
        secret_name = try(mtls.value.secret_name, null)
        url         = try(mtls.value.url, null)
      }
    }

    dynamic "proxy" {
      for_each = try(each.value.cnf.config.proxy, null) == null ? [] : [each.value.cnf.config.proxy]

      content {
        http_proxy  = try(proxy.value.http_proxy, null)
        https_proxy = try(proxy.value.https_proxy, null)
        no_proxy    = try(proxy.value.no_proxy, null)
        url         = try(proxy.value.url, null)
      }
    }
  }

  lifecycle {
    precondition {
      condition     = try(each.value.cnf.config.kubernetes.disable_namespace_creation, false)
      error_message = "Service Discovery Agent configs must set config.kubernetes.disable_namespace_creation to true; namespace creation belongs to the Kubernetes team."
    }

    precondition {
      condition     = trimspace(try(each.value.cnf.config.kubernetes.service_account, "")) != ""
      error_message = "Service Discovery Agent configs must name the Kubernetes-team-approved config.kubernetes.service_account."
    }
  }
}

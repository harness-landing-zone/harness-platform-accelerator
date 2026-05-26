resource "harness_platform_connector_github" "github_connector" {
  count       = lower(var.connector_type) == "github" ? 1 : 0
  project_id  = try(var.project_id, null)
  org_id      = try(var.org_id, null)
  name        = var.connector_name
  identifier  = var.connector_identifier != "" ? var.connector_identifier : replace(lower(var.connector_name), "/[^a-z0-9_]/", "_")
  description = var.connector_description
  tags        = var.connector_tags

  url                 = var.git_connector_url
  connection_type     = var.connection_type
  validation_repo     = var.validation_repo
  execute_on_delegate = var.execute_on_delegate
  delegate_selectors  = var.delegate_selectors

  credentials {
    # HTTP/GitHub App Auth
    dynamic "http" {
      for_each = var.git_connector_http_credentials != null ? [var.git_connector_http_credentials] : []
      content {
        username  = try(http.value.username, null)
        token_ref = try(http.value.token_ref, null)

        dynamic "github_app" {
          for_each = try(http.value.github_app, null) != null ? [http.value.github_app] : []
          content {
            application_id  = try(github_app.value.application_id, null)
            installation_id = try(github_app.value.installation_id, null)
            private_key_ref = github_app.value.private_key_ref
          }
        }
      }
    }

    # SSH Auth
    dynamic "ssh" {
      for_each = var.git_connector_ssh_credentials != null ? [var.git_connector_ssh_credentials] : []
      content {
        ssh_key_ref = ssh.value.ssh_key_ref
      }
    }
  }

  # API Authentication for Git Experience
  dynamic "api_authentication" {
    for_each = var.git_connector_api_auth != null ? [var.git_connector_api_auth] : []
    content {
      token_ref = try(api_authentication.value.token_ref, null)

      dynamic "github_app" {
        # Only inject if github_app_api is true AND we have credentials available
        for_each = try(api_authentication.value.github_app_api, false) ? [var.git_connector_http_credentials.github_app] : []
        content {
          application_id  = github_app.value.application_id
          installation_id = github_app.value.installation_id
          private_key_ref = github_app.value.private_key_ref
        }
      }
    }
  }
}

# Credentials http
resource "harness_platform_connector_git" "this" {
  count       = lower(var.connector_type) == "git" ? 1 : 0
  project_id  = try(var.project_id, null)
  org_id      = try(var.org_id, null)
  name        = var.connector_name
  identifier  = var.connector_identifier != "" ? var.connector_identifier : replace(lower(var.connector_name), "/[^a-z0-9_]/", "_")
  description = var.connector_description
  tags        = var.connector_tags

  url                 = var.git_connector_url
  connection_type     = var.connection_type
  validation_repo     = var.validation_repo
  execute_on_delegate = var.execute_on_delegate
  delegate_selectors  = var.delegate_selectors
  credentials {
    # HTTP/GitHub App Auth
    dynamic "http" {
      for_each = var.git_connector_http_credentials != null ? [var.git_connector_http_credentials] : []
      content {
        username     = try(http.value.username, null)
        password_ref = try(http.value.password_ref, null)

      }
    }

    # SSH Auth
    dynamic "ssh" {
      for_each = var.git_connector_ssh_credentials != null ? [var.git_connector_ssh_credentials] : []
      content {
        ssh_key_ref = ssh.value.ssh_key_ref
      }
    }
  }
}


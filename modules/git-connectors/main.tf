locals {
  # GitHub App API auth reuses the same App supplied via http credentials —
  # git_connector_api_auth only carries the github_app_api toggle (+ optional
  # token_ref), so the App credentials are read from git_connector_http_credentials.
  api_github_app         = try(var.git_connector_http_credentials.github_app, null)
  api_github_app_enabled = try(var.git_connector_api_auth.github_app_api, false) && local.api_github_app != null

  # Emit api_authentication only when it will carry usable auth: a token_ref, or
  # a resolvable GitHub App. This avoids dereferencing a null credentials object
  # AND avoids producing an empty (Harness-invalid) api_authentication block when
  # github_app_api is requested without any credentials.
  api_auth_usable = var.git_connector_api_auth != null && (
    try(var.git_connector_api_auth.token_ref, null) != null || local.api_github_app_enabled
  )
}

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
    for_each = local.api_auth_usable ? [var.git_connector_api_auth] : []
    content {
      token_ref = try(api_authentication.value.token_ref, null)

      dynamic "github_app" {
        # Reuse the http GitHub App; inject only when github_app_api is enabled
        # AND the App credentials actually resolved (null-safe — see locals).
        for_each = local.api_github_app_enabled ? [local.api_github_app] : []
        content {
          application_id  = try(github_app.value.application_id, null)
          installation_id = try(github_app.value.installation_id, null)
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


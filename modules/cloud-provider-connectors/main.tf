resource "harness_platform_connector_aws" "aws" {
  count = var.connector_type == "aws" ? 1 : 0

  name = var.connector_name
  identifier = (
    var.connector_identifier != null && trimspace(var.connector_identifier) != ""
    ? var.connector_identifier
    : replace(replace(lower(var.connector_name), " ", "_"), "-", "_")
  )
  description = (
    var.connector_description != null && trimspace(var.connector_description) != ""
    ? var.connector_description
    : null
  )
  tags = toset(try(var.connector_tags, []))

  # Optional scoping (account-level if both are null)
  org_id              = var.org_id != null && trimspace(var.org_id) != "" ? var.org_id : null
  project_id          = var.project_id != null && trimspace(var.project_id) != "" ? var.project_id : null
  execute_on_delegate = try(var.execute_on_delegate, null)
  force_delete        = try(var.force_delete, null)

  dynamic "cross_account_access" {
    for_each = var.aws_connector_cross_account_access != null ? [var.aws_connector_cross_account_access] : []
    content {
      role_arn    = cross_account_access.value.role_arn
      external_id = cross_account_access.value.external_id
    }
  }

  # Auth mode: inherit from delegate
  dynamic "inherit_from_delegate" {
    for_each = var.aws_connector_inherit_from_delegate != null ? [var.aws_connector_inherit_from_delegate] : []

    content {
      delegate_selectors = inherit_from_delegate.value.delegate_selectors
      region             = try(inherit_from_delegate.value.region, null)
    }
  }

  # Auth mode: manual keys
  dynamic "manual" {
    for_each = var.aws_connector_manual_authentication != null ? [var.aws_connector_manual_authentication] : []

    content {
      access_key_ref     = manual.value.access_key_ref
      secret_key_ref     = manual.value.secret_key_ref
      delegate_selectors = manual.value.delegate_selectors
      region             = try(manual.value.region, null)
    }
  }

  # Auth mode: irsa
  dynamic "irsa" {
    for_each = var.aws_connector_irsa_authentication != null ? [var.aws_connector_irsa_authentication] : []

    content {
      delegate_selectors = irsa.value.delegate_selectors
      region             = try(irsa.value.region, null)
    }
  }

  # Auth mode: OIDC
  dynamic "oidc_authentication" {
    for_each = var.aws_connector_oidc_authentication != null ? [var.aws_connector_oidc_authentication] : []

    content {
      iam_role_arn       = oidc_authentication.value.iam_role_arn
      delegate_selectors = oidc_authentication.value.delegate_selectors
      region             = oidc_authentication.value.region
    }
  }

  dynamic "equal_jitter_backoff_strategy" {
    for_each = var.aws_connector_equal_jitter_backoff_strategy != null ? [var.aws_connector_equal_jitter_backoff_strategy] : []
    content {
      base_delay       = equal_jitter_backoff_strategy.value.base_delay
      max_backoff_time = equal_jitter_backoff_strategy.value.max_backoff_time
      retry_count      = equal_jitter_backoff_strategy.value.retry_count
    }
  }

  dynamic "full_jitter_backoff_strategy" {
    for_each = var.aws_connector_full_jitter_backoff_strategy != null ? [var.aws_connector_full_jitter_backoff_strategy] : []
    content {
      base_delay       = full_jitter_backoff_strategy.value.base_delay
      max_backoff_time = full_jitter_backoff_strategy.value.max_backoff_time
      retry_count      = full_jitter_backoff_strategy.value.retry_count
    }
  }

  dynamic "fixed_delay_backoff_strategy" {
    for_each = var.aws_connector_fixed_delay_backoff_strategy != null ? [var.aws_connector_fixed_delay_backoff_strategy] : []
    content {
      fixed_backoff = fixed_delay_backoff_strategy.value.fixed_backoff
      retry_count   = fixed_delay_backoff_strategy.value.retry_count
    }
  }

  lifecycle {
    precondition {
      condition = (
        (var.aws_connector_manual_authentication != null ? 1 : 0) +
        (var.aws_connector_inherit_from_delegate != null ? 1 : 0) +
        (var.aws_connector_oidc_authentication != null ? 1 : 0) +
        (var.aws_connector_irsa_authentication != null ? 1 : 0)
      ) == 1
      error_message = "Exactly one auth mode must be enabled: manual, inherit_from_delegate, oidc_authentication or irsa."
    }

    precondition {
      condition = (
        (var.aws_connector_equal_jitter_backoff_strategy != null ? 1 : 0) +
        (var.aws_connector_full_jitter_backoff_strategy != null ? 1 : 0) +
        (var.aws_connector_fixed_delay_backoff_strategy != null ? 1 : 0)
      ) <= 1
      error_message = "At most one backoff strategy can be enabled."
    }
  }
}

resource "harness_platform_connector_gcp" "gcp" {
  count = var.connector_type == "gcp" ? 1 : 0

  name = var.connector_name
  identifier = (
    var.connector_identifier != null && trimspace(var.connector_identifier) != ""
    ? var.connector_identifier
    : replace(replace(lower(var.connector_name), " ", "_"), "-", "_")
  )
  description = (
    var.connector_description != null && trimspace(var.connector_description) != ""
    ? var.connector_description
    : null
  )
  tags = toset(try(var.connector_tags, []))

  # Optional scoping (account-level if both are null)
  org_id     = var.org_id != null && trimspace(var.org_id) != "" ? var.org_id : null
  project_id = var.project_id != null && trimspace(var.project_id) != "" ? var.project_id : null

  # Auth mode: OIDC
  dynamic "oidc_authentication" {
    for_each = var.gcp_connector_oidc_authentication != null ? [var.gcp_connector_oidc_authentication] : []

    content {
      workload_pool_id      = oidc_authentication.value.workload_pool_id
      provider_id           = oidc_authentication.value.provider_id
      gcp_project_id        = oidc_authentication.value.gcp_project_id
      service_account_email = oidc_authentication.value.service_account_email
      delegate_selectors    = try(oidc_authentication.value.delegate_selectors, [])
    }
  }

  # Auth mode: manual (service account key)
  dynamic "manual" {
    for_each = var.gcp_connector_manual_authentication != null ? [var.gcp_connector_manual_authentication] : []

    content {
      secret_key_ref     = manual.value.secret_key_ref
      delegate_selectors = try(manual.value.delegate_selectors, [])
    }
  }

  # Auth mode: inherit from delegate
  dynamic "inherit_from_delegate" {
    for_each = var.gcp_connector_inherit_from_delegate != null ? [var.gcp_connector_inherit_from_delegate] : []

    content {
      delegate_selectors = inherit_from_delegate.value.delegate_selectors
    }
  }

  lifecycle {
    precondition {
      condition = (
        (var.gcp_connector_oidc_authentication != null ? 1 : 0) +
        (var.gcp_connector_manual_authentication != null ? 1 : 0) +
        (var.gcp_connector_inherit_from_delegate != null ? 1 : 0)
      ) == 1
      error_message = "Exactly one GCP auth mode must be enabled: oidc_authentication, manual, or inherit_from_delegate."
    }
  }
}

resource "harness_platform_connector_kubernetes" "kubernetes" {
  count = var.connector_type == "kubernetes" ? 1 : 0

  name = var.connector_name
  identifier = (
    var.connector_identifier != null && trimspace(var.connector_identifier) != ""
    ? var.connector_identifier
    : replace(replace(lower(var.connector_name), " ", "_"), "-", "_")
  )
  description = (
    var.connector_description != null && trimspace(var.connector_description) != ""
    ? var.connector_description
    : null
  )
  tags = toset(try(var.connector_tags, []))

  # Optional scoping (account-level if both are null)
  org_id       = var.org_id != null && trimspace(var.org_id) != "" ? var.org_id : null
  project_id   = var.project_id != null && trimspace(var.project_id) != "" ? var.project_id : null
  force_delete = try(var.force_delete, null)

  # Conflicts with inherit_from_delegate (which carries its own selectors)
  delegate_selectors = var.k8s_connector_inherit_from_delegate != null ? null : toset(try(var.delegate_selectors, []))

  # Auth mode: inherit from delegate
  dynamic "inherit_from_delegate" {
    for_each = var.k8s_connector_inherit_from_delegate != null ? [var.k8s_connector_inherit_from_delegate] : []
    content {
      delegate_selectors = inherit_from_delegate.value.delegate_selectors
    }
  }

  # Auth mode: username / password
  dynamic "username_password" {
    for_each = var.k8s_connector_username_password != null ? [var.k8s_connector_username_password] : []
    content {
      master_url   = username_password.value.master_url
      password_ref = username_password.value.password_ref
      username     = try(username_password.value.username, null)
      username_ref = try(username_password.value.username_ref, null)
    }
  }

  # Auth mode: service account token
  dynamic "service_account" {
    for_each = var.k8s_connector_service_account != null ? [var.k8s_connector_service_account] : []
    content {
      master_url                = service_account.value.master_url
      service_account_token_ref = service_account.value.service_account_token_ref
      ca_cert_ref               = try(service_account.value.ca_cert_ref, null)
    }
  }

  # Auth mode: client key / cert
  dynamic "client_key_cert" {
    for_each = var.k8s_connector_client_key_cert != null ? [var.k8s_connector_client_key_cert] : []
    content {
      master_url                = client_key_cert.value.master_url
      client_cert_ref           = client_key_cert.value.client_cert_ref
      client_key_ref            = client_key_cert.value.client_key_ref
      client_key_algorithm      = client_key_cert.value.client_key_algorithm
      ca_cert_ref               = try(client_key_cert.value.ca_cert_ref, null)
      client_key_passphrase_ref = try(client_key_cert.value.client_key_passphrase_ref, null)
    }
  }

  # Auth mode: OpenID Connect
  dynamic "openid_connect" {
    for_each = var.k8s_connector_openid_connect != null ? [var.k8s_connector_openid_connect] : []
    content {
      master_url    = openid_connect.value.master_url
      issuer_url    = openid_connect.value.issuer_url
      client_id_ref = openid_connect.value.client_id_ref
      password_ref  = openid_connect.value.password_ref
      username      = try(openid_connect.value.username, null)
      username_ref  = try(openid_connect.value.username_ref, null)
      secret_ref    = try(openid_connect.value.secret_ref, null)
      scopes        = try(openid_connect.value.scopes, null)
    }
  }

  lifecycle {
    precondition {
      condition = (
        (var.k8s_connector_inherit_from_delegate != null ? 1 : 0) +
        (var.k8s_connector_username_password != null ? 1 : 0) +
        (var.k8s_connector_service_account != null ? 1 : 0) +
        (var.k8s_connector_client_key_cert != null ? 1 : 0) +
        (var.k8s_connector_openid_connect != null ? 1 : 0)
      ) == 1
      error_message = "Exactly one Kubernetes auth mode must be enabled: inherit_from_delegate, username_password, service_account, client_key_cert, or openid_connect."
    }
  }
}

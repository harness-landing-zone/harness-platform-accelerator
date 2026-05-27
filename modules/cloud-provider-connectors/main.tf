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

resource "harness_platform_connector_azure" "azure" {
  count = var.connector_type == "azure" ? 1 : 0

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

  force_delete = try(var.force_delete, null)

  # Auth mode: Service Principal (most common)
  dynamic "credentials" {
    for_each = var.azure_connector_service_principal != null ? [var.azure_connector_service_principal] : []

    content {
      type = "Secret"

      azure_client_secret_key {
        client_id          = credentials.value.client_id
        tenant_id          = credentials.value.tenant_id
        secret_ref         = credentials.value.secret_ref
        delegate_selectors = try(credentials.value.delegate_selectors, [])
      }
    }
  }

  # Auth mode: Managed Identity (for delegates running on Azure)
  dynamic "credentials" {
    for_each = var.azure_connector_managed_identity != null ? [var.azure_connector_managed_identity] : []

    content {
      type = "ManagedIdentity"

      azure_managed_identity {
        client_id          = credentials.value.client_id
        tenant_id          = credentials.value.tenant_id
        delegate_selectors = credentials.value.delegate_selectors
      }
    }
  }

  # Auth mode: Certificate (less common, for certificate-based authentication)
  dynamic "credentials" {
    for_each = var.azure_connector_certificate != null ? [var.azure_connector_certificate] : []

    content {
      type = "Certificate"

      azure_client_certificate_key {
        client_id          = credentials.value.client_id
        tenant_id          = credentials.value.tenant_id
        certificate_ref    = credentials.value.certificate_ref
        delegate_selectors = try(credentials.value.delegate_selectors, [])
      }
    }
  }

  lifecycle {
    precondition {
      condition = (
        (var.azure_connector_service_principal != null ? 1 : 0) +
        (var.azure_connector_managed_identity != null ? 1 : 0) +
        (var.azure_connector_certificate != null ? 1 : 0)
      ) == 1
      error_message = "Exactly one Azure auth mode must be enabled: service_principal, managed_identity, or certificate."
    }
  }
}

# Live permissions lookup — used by harness_roles.tf for validation.
data "harness_platform_permissions" "current" {}

##############################################################################
# Organization scope
# Created only when scope == "organization".
##############################################################################

resource "harness_platform_organization" "selected" {
  count = local.scope == "organization" ? 1 : 0

  identifier  = local.org_identifier
  name        = local.org_name
  description = local.org_description
  tags        = local.common_tags_tuple
}

# Data source — resolves after creation (org scope) or looks up existing (project scope).
data "harness_platform_organization" "selected" {
  count = local.scope != "account" ? 1 : 0

  identifier = (
    local.scope == "organization"
    ? harness_platform_organization.selected[0].id
    : local.org_identifier
  )
}

##############################################################################
# Project scope
# Created only when scope == "project".
##############################################################################

resource "harness_platform_project" "selected" {
  count = local.scope == "project" ? 1 : 0

  identifier = local.project_identifier
  name       = var.project_name
  # Use local.org_identifier (always a known string at plan time) rather than
  # the data source, which becomes (known after apply) when the calling module
  # has depends_on — preventing forced replacements on subsequent plans.
  org_id      = local.org_identifier
  description = var.project_description
  tags        = local.common_tags_tuple
}

# Brief delay after project creation to avoid race conditions.
resource "time_sleep" "project_setup" {
  count      = local.scope == "project" ? 1 : 0
  depends_on = [harness_platform_project.selected]

  create_duration = "15s"
}

data "harness_platform_project" "selected" {
  count      = local.scope == "project" ? 1 : 0
  depends_on = [time_sleep.project_setup]

  identifier = harness_platform_project.selected[0].id
  org_id     = data.harness_platform_organization.selected[0].id
}

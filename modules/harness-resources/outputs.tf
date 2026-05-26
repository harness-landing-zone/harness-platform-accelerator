locals {
  organization_url = local.scope == "organization" ? join("/", [
    trimsuffix(replace(var.harness_platform_url, "gateway", "ng"), "/"),
    "account",
    var.harness_platform_account,
    "all/orgs",
    one(data.harness_platform_organization.selected[*].id),
    "projects"
  ]) : null

  project_url = local.scope == "project" ? join("/", [
    trimsuffix(replace(var.harness_platform_url, "gateway", "ng"), "/"),
    "account",
    var.harness_platform_account,
    "all/orgs",
    local.resolved_org_id,
    "projects",
    local.resolved_project_id,
    "overview"
  ]) : null
}

output "scope" {
  description = "Detected deployment scope: account | organization | project"
  value       = local.scope
}

output "organization_id" {
  description = "Organization identifier/ID (null at account scope)"
  value       = local.resolved_org_id
}

output "organization_identifier" {
  description = "Organization identifier (null at account scope)"
  value       = one(data.harness_platform_organization.selected[*].identifier)
}

output "organization_url" {
  description = "Harness UI URL for the organization (null when not organization scope)"
  value       = local.organization_url
}

output "project_identifier" {
  description = "Project identifier (null when not project scope)"
  value       = one(data.harness_platform_project.selected[*].identifier)
}

output "project_url" {
  description = "Harness UI URL for the project (null when not project scope)"
  value       = local.project_url
}

output "platform_configs_dir" {
  description = "Resolved absolute path to the platform-configs root"
  value       = local.platform_configs_dir
}

output "source_directory" {
  description = "Resolved absolute path to the template (global defaults) directory"
  value       = local.source_directory
}

output "org_directory" {
  description = "Resolved absolute path to the org config directory"
  value       = local.org_directory
}

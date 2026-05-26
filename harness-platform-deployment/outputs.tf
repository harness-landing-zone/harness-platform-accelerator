output "deployed_scope" {
  description = "Active deployment mode: account | organization | project"
  value = (
    var.scope_level == "project" ? "project" :
    "organization"
  )
}

output "organization_url" {
  description = "Harness UI URL for the deployed org (null when not org scope)"
  value       = var.scope_level == "organization" ? one(module.organization[*].organization_url) : null
}

output "project_url" {
  description = "Harness UI URL for the deployed project (null when not project scope)"
  value       = var.scope_level == "project" ? one(module.project[*].project_url) : null
}

output "deployed_projects" {
  description = "Map of folder-key → project identifier for org-bootstrap runs"
  value       = { for k, m in module.projects : k => m.project_identifier }
}

output "platform_configs_repo_name" {
  description = "Name of the platform-configs repository"
  value       = var.platform_configs_repo_name
}
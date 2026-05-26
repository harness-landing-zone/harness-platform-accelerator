output "workspace_id" {
  description = "Harness workspace ID."
  value       = harness_platform_workspace.workspace.id
}

output "workspace_identifier" {
  description = "Harness workspace identifier."
  value       = harness_platform_workspace.workspace.identifier
}

output "workspace_name" {
  description = "Harness workspace display name."
  value       = harness_platform_workspace.workspace.name
}

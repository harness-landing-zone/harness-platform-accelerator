output "connector_id" {
  description = "Harness connector ID."
  value       = one(harness_platform_connector_vault.vault[*].id)
}

output "connector_identifier" {
  description = "Harness connector identifier."
  value       = one(harness_platform_connector_vault.vault[*].identifier)
}

output "connector_name" {
  description = "Harness connector display name."
  value       = one(harness_platform_connector_vault.vault[*].name)
}

output "connector_id" {
  description = "Harness connector ID."
  value       = var.connector_type == "gcp" ? harness_platform_connector_gcp.gcp[0].id : harness_platform_connector_aws.aws[0].id
}

output "connector_identifier" {
  description = "Harness connector identifier."
  value       = var.connector_type == "gcp" ? harness_platform_connector_gcp.gcp[0].identifier : harness_platform_connector_aws.aws[0].identifier
}

output "connector_name" {
  description = "Harness connector display name."
  value       = var.connector_type == "gcp" ? harness_platform_connector_gcp.gcp[0].name : harness_platform_connector_aws.aws[0].name
}

locals {
  _connector = (
    var.connector_type == "gcp" ? harness_platform_connector_gcp.gcp[0] :
    var.connector_type == "kubernetes" ? harness_platform_connector_kubernetes.kubernetes[0] :
    harness_platform_connector_aws.aws[0]
  )
}

output "connector_id" {
  description = "Harness connector ID."
  value       = local._connector.id
}

output "connector_identifier" {
  description = "Harness connector identifier."
  value       = local._connector.identifier
}

output "connector_name" {
  description = "Harness connector display name."
  value       = local._connector.name
}

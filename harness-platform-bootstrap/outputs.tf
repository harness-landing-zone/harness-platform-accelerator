output "platform_deployer_service_account" {
  description = "Identifier of the platform-deployer service account."
  value       = harness_platform_service_account.harness_bootstrap.identifier
}

output "platform_deployer_token_secret" {
  description = "Identifier of the token secret the deploy pipelines reference via <+secrets.getValue(...)>."
  value       = local.deployer_secret_id
}

output "organization_id" {
  description = "Identifier of the bootstrapped organization."
  value       = module.platform_management.organization_id
}

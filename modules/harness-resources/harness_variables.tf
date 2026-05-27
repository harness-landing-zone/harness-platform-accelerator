# Variables can be defined at account, organization, or project scope
# They provide centralized configuration management and can be referenced
# in pipelines, services, and other resources using <+variable.name> syntax

locals {
  variables_configs = try(local.merged_sources["variables"], {})
}

##############################################################################
# Platform Variables
# Centralized variable management for reusable configuration values
##############################################################################

resource "harness_platform_variables" "variables" {
  for_each = local.variables_configs

  identifier = each.value.identifier
  name       = each.value.name
  org_id     = local.resolved_org_id
  project_id = local.resolved_project_id

  description = lookup(each.value.cnf, "description", "Harness variable managed by Solutions Factory")

  # Variable type: String, Number, Secret
  type = lookup(each.value.cnf, "type", "String")

  # Variable spec - contains value and optional properties
  spec {
    # Value type determines how the value is stored
    value_type = lookup(each.value.cnf.spec, "value_type", "FIXED") # FIXED, RUNTIME, EXPRESSION

    # For FIXED values - the actual value
    fixed_value = lookup(each.value.cnf.spec, "fixed_value", null)

    # For RUNTIME values - optional default value
    default_value = lookup(each.value.cnf.spec, "default_value", null)

    # For Secret type - reference to secret
    secret_value_ref = lookup(each.value.cnf.spec, "secret_value_ref", null)

    # Allowed values (for validation)
    allowed_values = try(each.value.cnf.spec.allowed_values, null)

    # Regex pattern for validation
    regex = lookup(each.value.cnf.spec, "regex", null)
  }

  lifecycle {
    precondition {
      condition = contains([
        "String",
        "Number",
        "Secret"
      ], lookup(each.value.cnf, "type", "String"))
      error_message = "Invalid variable type. Must be one of: String, Number, Secret."
    }

    precondition {
      condition = contains([
        "FIXED",
        "RUNTIME",
        "EXPRESSION"
      ], lookup(each.value.cnf.spec, "value_type", "FIXED"))
      error_message = "Invalid value_type. Must be one of: FIXED, RUNTIME, EXPRESSION."
    }

    precondition {
      condition = (
        lookup(each.value.cnf, "type", "String") == "Secret"
        ? lookup(each.value.cnf.spec, "secret_value_ref", null) != null
        : true
      )
      error_message = "Secret type variables must have secret_value_ref in spec."
    }
  }
}

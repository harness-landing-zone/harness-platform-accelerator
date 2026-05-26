package template

########################
# Governance Policy for Harness Templates
#
# Enforces template versionLabel naming convention:
#   v<MAJOR>.<MINOR>.<PATCH>  (e.g., v1.0.0)
########################

#### BEGIN - Policy Controls ####
version_format = "^v[0-9]+\\.[0-9]+\\.[0-9]+$"

error_msg = [
  "The versionLabel (%s) of this template does not match the supported version format.",
  "Required format: v<MAJOR>.<MINOR>.<PATCH> (e.g., v1.0.0)."
]
#### END   - Policy Controls ####

#### BEGIN - Policy Evaluation ####
deny[msg] {
  template_version := input.template.versionLabel
  not regex.match(version_format, template_version)

  msg := sprintf(concat(" ", error_msg), [template_version])
}
#### END   - Policy Evaluation ####

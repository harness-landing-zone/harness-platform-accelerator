package harness_iacm

# ============================================================
# Configuration - Allowed module sources
# ============================================================

# Local relative paths are always allowed (never add these to the list)
local_prefixes := {"./", "../"}

# Allowed remote registries - add new entries here as needed
allowed_registries := {
  "app.harness.io/qIYsos1ZQO6fJMG1Ip6KJA",   # Harness Registry - Primary Account
  "app.harness.io/aXkP9mNqR3wLtY7cH2vBsE",   # Harness Registry - Secondary Account (example)
  "git.internal.company.com/terraform-modules" # Internal Git Registry (example)
}

# ============================================================
# Helpers
# ============================================================

# Walk the full config tree and collect all module_calls entries
module_calls[call] {
  walk(input.configuration.root_module, [p, v])
  p[count(p)-1] == "module_calls"
  mc := v[_]
  call := mc
}

# A source is local if it starts with any local prefix
is_local(source) {
  some prefix
  prefix := local_prefixes[_]
  startswith(source, prefix)
}

# A source is from an allowed registry if it starts with any allowed registry
is_allowed_registry(source) {
  some registry
  registry := allowed_registries[_]
  startswith(source, registry)
}

# ============================================================
# Rules
# ============================================================

deny[msg] {
  call := module_calls[_]

  # Not a local path
  not is_local(call.source)

  # Not from any allowed registry
  not is_allowed_registry(call.source)

  msg := sprintf(
    "Module source %q is not allowed. Permitted sources are local paths ('./','../') or approved registries: %v",
    [call.source, allowed_registries]
  )
}
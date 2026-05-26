########################
# Governance Policy for Harness Tokens
# Policy: Enforce API Key Token Age
#
# This policy will enforce that all Harness API Tokens created will adhere to a
# strict max age policy.
#
########################
package pipeline

import future.keywords.if
import future.keywords.in

#### BEGIN - Policy Controls ####
#
# Inputs:
#   maximum_years = How many years can a token be created.
#   maximum_months = How many months can a token be created.
#   maximum_days = How many days can a token be created.

# Control Board
maximum_years = 0
maximum_months = 2
maximum_days = 60

tokens_with_exceptions = [
    {"service_account": "harness_platform_manager", "api_key": "platform_manager"}
]

#### END   - Policy Controls ####

#### BEGIN - Policy Validation ####

token_created := return_formatted_epoch(input.token.validFrom)
token_valid_till := time.add_date(return_formatted_epoch(input.token.validTo),0, 0, 0)

# Returns as an array of numbers in the format of
# [years, months, days, hours, minutes, seconds]
time_diff := time.diff(token_created, token_valid_till)

# Deny pipelines that use forbidden items in steps not included in approved templates
deny[msg] {
    not token_has_exception
    restrict_token_age
    msg := sprintf("Invalid Length for Token Creation. Harness Access Tokens may only be created for up to %s days", [format_notation(maximum_days)])
}

# Handler for token enforcement if the token is Account Scoped
token_has_exception if {
    not has_key(input.token, "orgIdentifier")
    not has_key(input.token, "projectIdentifier")
    some exception in tokens_with_exceptions
    input.token.parentIdentifier == exception.service_account
    input.token.apiKeyIdentifier == exception.api_key
    # Match account-level tokens (no org in exception and no orgIdentifier in token)
    not has_key(exception, "org")
    not has_key(exception, "project")
}

# Handler for token enforcement if the token is Organization Scoped
token_has_exception if {
    has_key(input.token, "orgIdentifier")
    not has_key(input.token, "projectIdentifier")
    some exception in tokens_with_exceptions
    input.token.parentIdentifier == exception.service_account
    input.token.apiKeyIdentifier == exception.api_key
    # Match org-level tokens (org in exception matches orgIdentifier in token)
    exception_org := object.get(exception, "org", null)
    token_org := object.get(input.token, "orgIdentifier", null)
    exception_org != null
    token_org != null
    exception_org == token_org
    not has_key(exception, "project")
}

# Handler for token enforcement if the token is Project Scoped
token_has_exception if {
    has_key(input.token, "orgIdentifier")
    has_key(input.token, "projectIdentifier")
    some exception in tokens_with_exceptions
    input.token.parentIdentifier == exception.service_account
    input.token.apiKeyIdentifier == exception.api_key
    # Match org-level tokens (org in exception matches orgIdentifier in token)
    exception_org := object.get(exception, "org", null)
    token_org := object.get(input.token, "orgIdentifier", null)
    exception_org != null
    token_org != null
    exception_org == token_org
    # Match project-level tokens (project in exception matches projectIdentifier in token)
    exception_project := object.get(exception, "project", null)
    token_project := object.get(input.token, "projectIdentifier", null)
    exception_project != null
    token_project != null
    exception_project == token_project
}

restrict_token_age if {
    # Raise an issue if the maximum years for the token exceeds value
    time_diff[0] > maximum_years
} else if {
    # Raise an issue if the maximum months for the token exceeds value
    time_diff[1] > maximum_months
} else if {
    # Raise an issue if the maximum days for the token exceeds value and account
    # for a matching days value by supporting a 24hr option as well
    time_diff[2] >= maximum_days
    time_diff[3] != 0
} else := false

#### END   - Policy Validation ####

#### BEGIN - Policy Helper Functions ####

# Return a nanosecond formatted epoch timestamp
return_formatted_epoch(time_input) := output if {
    output := time_input * 1000000
}
# Rego does not like to combine integers into a string when concatenating.  This will ensure that the
# number is formatted as a string using a base10 eval
format_notation(eval_elem) := format_int(eval_elem, 10) if is_number(eval_elem)

has_key(x, k) if {
    _ = x[k]
}
#### END   - Policy Helper Functions ####

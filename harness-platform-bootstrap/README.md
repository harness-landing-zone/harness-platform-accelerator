# Harness Platform Bootstrap

Local bootstrap entrypoint for the Harness Landing Zone chicken-and-egg setup.

This folder is used before the shared Harness pipeline can manage the platform for itself. It creates the first organization and projects, seeds the bootstrap Git connector and secrets, and creates the service account and token used by the pipeline that will take over later.

## Purpose

Use this entrypoint to stand up the initial platform-management footprint:

- The first Harness organization (by default, `Harness Platform Accelerator`)
- Its starter projects (`Platform Management`)
- Org-scoped resources from the embedded `organizations/` config tree
- A deploy service account, named after the org, with its API key, token, and a secret that holds the token
- The deploy pipelines, imported from the `.harness/` folder

This entrypoint is meant to be run locally. It is not the long-term deployment path.

## Before you start

You need:

- [OpenTofu](https://opentofu.org/docs/intro/install/) installed (the `tofu` command)
- A Harness account and a Platform API key with account-admin rights
- A GitHub App that can read your config repo (only if you keep the Git connector)

Some values are specific to your setup. Set these before you apply:

- `organization_name`, and the matching folder name under `organizations/`
- `harness_platform_account` (your Harness account ID)
- in `organizations/<org>/git-connectors/platform_configs.yaml`: the `connector_url` (your GitHub org, not the example) and the GitHub App `application_id` / `installation_id`

## How It Works

This folder is a thin wrapper around the shared module in [../modules/harness-resources](../modules/harness-resources).

- [main.tf](./main.tf) points the module at this folder's own `organizations/` tree, so the bootstrap is self-contained and does not need an external config repo.
- [harness_service_accounts.tf](./harness_service_accounts.tf) creates the deploy service account and stores its token as a secret named after the org (for the default org, `harness_platform_accelerator_platform_deployer_token`). The deploy pipelines read this secret to log in to Harness.
- The pipeline definitions live in [.harness/](./.harness/) in this folder. Each project's `pipelines/*.yaml` files are small pointers that tell Harness which `.harness/` file to import.

## Authentication

There is no `providers.tf` in this folder, so the `harness/harness` provider is
configured **entirely from environment variables**. Before running any `tofu`
command you must export, at minimum, your account ID and a Platform (NextGen)
API key:

```bash
export HARNESS_ACCOUNT_ID="<your-account-id>"
export HARNESS_PLATFORM_API_KEY="pat.<your-account-id>.xxxxxxxx.yyyyyyyy"
# Optional — only for self-hosted / custom-domain instances:
# export HARNESS_ENDPOINT="https://app.harness.io/gateway"
```

- Use a **Platform API key** (`HARNESS_PLATFORM_API_KEY`), not a FirstGen
  `HARNESS_API_KEY` — these resources are NextGen.
- The key needs account-admin level rights, because the bootstrap creates a
  service account and an **account-admin role assignment**.
- Without these, `tofu plan` fails fast with `account_id is not set` and
  `401 Unauthorized` on the `harness_platform_permissions` lookup.

`var.harness_platform_account` (used to stamp `account_id` on resources) is
separate from the provider's `HARNESS_ACCOUNT_ID`; set both to the same value.

## Backend

This entrypoint defaults to **local state** — the `backend "gcs" {}` block in
[terraform.tf](./terraform.tf) is commented out, so no GCS bucket or GCP
credentials are required to run it locally. The `gcs_bucket` / `gcp_*` variables
are optional and consumed only by the deploy pipeline (for `tofu init
-backend-config` and OIDC), never by a resource in this module.

```bash
cd harness-platform-bootstrap
tofu init          # local state, no backend config needed
```

To use a remote GCS backend instead, uncomment the `backend "gcs" {}` block and
init with the bucket/prefix:

```bash
tofu init \
  -backend-config="bucket=<gcs-bucket>" \
  -backend-config="prefix=<state-prefix>"
```

## Inputs

Minimum required inputs:

- `harness_platform_account` — your Harness account ID (supply per environment via `terraform.tfvars` or `HARNESS_ACCOUNT_ID`)
- `organization_name` — the org **config-folder name** under `organizations/`
  (defaults to `hpa`). This selects which config tree
  to deploy; the org display name and identifier come from that folder's
  `config.yaml`, falling back to this value only when `config.yaml` omits them.

Optional inputs:

- `harness_platform_url`
- `tags`
- `git_connector_credentials` — required if a git-connector YAML declares
  `api_auth`/`github_app` without inline credentials (see Current Caveats).

Expected local-only artifacts:

- `terraform.tfvars` (gitignored) for any overrides
- `pem-folder/` contents for file-type secrets

Credentials should come from environment variables or gitignored local files, never committed config.

## Git Connector Credentials

The `platform_configs` GitHub connector uses **GitHub App** auth. Harness
requires every GitHub connector to declare credentials (`http` or `ssh`), so the
App coordinates must be supplied one of two ways. **Neither exposes secret
material:** `application_id` and `installation_id` are non-secret identifiers,
and `private_key_ref` is a *reference* to the PEM secret (created from
`secrets/github_app_key.yaml`, identifier `harness_lz_key`), never the key itself.

**Way 1 — inline in the connector YAML** (`git-connectors/platform_configs.yaml`):

```yaml
http_credentials:
  github_app:
    application_id: "123456"
    installation_id: "12345678"
    private_key_ref: org.harness_lz_key
api_auth:
  github_app_api: true
```

**Way 2 — via the `git_connector_credentials` variable**, keyed by connector
identifier. Omit the `http_credentials` block from the YAML and supply it either
as an env var:

```bash
export TF_VAR_git_connector_credentials='{"platform_configs":{"http_credentials":{"github_app":{"application_id":"123456","installation_id":"12345678","private_key_ref":"org.harness_lz_key"}},"api_auth":{"github_app_api":true}}}'
```

or in a gitignored `terraform.tfvars`:

```hcl
git_connector_credentials = {
  platform_configs = {
    http_credentials = {
      github_app = {
        application_id  = "123456"
        installation_id = "12345678"
        private_key_ref = "org.harness_lz_key"
      }
    }
    api_auth = { github_app_api = true }
  }
}
```

**Resolution order:** inline YAML wins; the variable is the fallback
(`try(cnf.http_credentials, var.git_connector_credentials[<id>].http_credentials, null)`).
Use **Way 1** for shared, non-secret coordinates checked into the repo; use
**Way 2** when injecting at runtime — the `bootstrap_deploy` pipeline builds this
exact JSON from its `github_app_*` pipeline variables.

## Embedded Config Tree

This entrypoint reads config from its own local tree:

```text
harness-platform-bootstrap/
├── .harness/                           # pipeline definitions, imported into Harness
└── organizations/
    └── hpa/                            # folder name == organization_name
        ├── config.yaml                 # org name + identifier
        ├── git-connectors/
        ├── secrets/
        └── projects/
            ├── Infrastructure/
            └── Platform Management/
                ├── config.yaml
                └── pipelines/          # pointers to the .harness/ files above
```

That makes this folder self-contained for the initial bootstrap run.

## Intended Lifecycle

1. Run this folder locally to create the first org, first projects, bootstrap connector, bootstrap secrets, and the deployer service account.
2. Use the bootstrap pipeline in Harness to provision additional environments.
3. Migrate the pipeline to use [harness-platform-deployment](../harness-platform-deployment) as the root consumer once that flow is validated.
4. Use the reusable modules behind that root:
   `harness-platform-setup`, `harness-organization`, and `harness-project`.

Two pipeline execution modes are planned for the steady state:

- Git-driven
- Harness workflow-driven

## Suggested Workflow

From this directory:

```bash
# 1. Authenticate (see Authentication section)
export HARNESS_ACCOUNT_ID="<your-account-id>"
export HARNESS_PLATFORM_API_KEY="pat.<your-account-id>.xxxx.yyyy"

# 2. Init with local state (no backend config needed)
tofu init

# 3. Validate and review
tofu validate
tofu plan
```

Do not run `tofu apply` unless explicitly intended for the bootstrap step.

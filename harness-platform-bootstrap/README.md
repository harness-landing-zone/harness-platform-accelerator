# Harness Platform Bootstrap

Local bootstrap entrypoint for the Harness Landing Zone chicken-and-egg setup.

This folder is used before the shared Harness pipeline can manage the platform for itself. It creates the first organization and projects, seeds the bootstrap Git connector and secrets, and creates the service account and token used by the pipeline that will take over later.

## Purpose

Use this entrypoint to stand up the initial platform-management footprint:

- The first Harness organization, currently `Platform Management`
- The initial bootstrap projects under that organization
- Org-scoped resources from the embedded `organizations/` config tree
- The account-scoped `tofu_deployer` service account, API key, token, and secret
- The bootstrap pipeline definitions stored under the project `.harness/` folder

This entrypoint is intended to be run locally. It is not the long-term steady-state deployment path.

## How It Works

The root module in this folder is a thin consumer around the reusable [harness-organization](../harness-organization) module.

- [harness_organization.tf](./harness_organization.tf) points `harness-organization` at this folder's own `organizations/` directory instead of the external `platform-configs` repo.
- [harness_service_accounts.tf](./harness_service_accounts.tf) creates the bootstrap service account and stores its token in the Harness secret manager as `account.harness_platform_api_key`.
- The bootstrap pipeline definitions live under:
  - [tofu_deploy.yaml](./organizations/Platform%20Management/projects/Platform%20Management/.harness/tofu_deploy.yaml)
  - [trigger_on_push.yaml](./organizations/Platform%20Management/projects/Platform%20Management/.harness/trigger_on_push.yaml)

## Backend

This entrypoint uses a GCS backend from [terraform.tf](./terraform.tf).

Provide the backend settings at init time. Do not hardcode backend credentials in the repo.

Example:

```bash
cd harness-platform-bootstrap
tofu init \
  -backend-config="bucket=<gcs-bucket>" \
  -backend-config="prefix=<state-prefix>"
```

## Inputs

Minimum required inputs:

- `harness_platform_account`
- `organization_name` if you are not using the default `Platform Management`

Optional inputs:

- `harness_platform_url`
- `tags`
- `git_connector_credentials`

Expected local-only artifacts:

- `terraform.tfvars`
- `providers.tf` if you are not using environment variables
- `pem/` contents for file-type secrets

Credentials should come from environment variables or gitignored local files, never committed config.

## Embedded Config Tree

This entrypoint reads config from its own local tree:

```text
harness-platform-bootstrap/
└── organizations/
    └── Platform Management/
        ├── config.yaml
        ├── git-connectors/
        ├── secrets/
        └── projects/
            ├── Infrastructure/
            └── Platform Management/
                └── .harness/
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

## Current Caveats

- The bootstrap config currently references template names such as `bootstrap-org`, `bootstrap-project`, and `templates-two`, but those directories are not present in the repo yet.
- [local-tests.tf](./local-tests.tf) is a local/dev artifact and should not be relied on as committed configuration.
- This folder is for bootstrap only. Do not treat it as the final long-term deployment root.

## Suggested Workflow

From this directory:

```bash
tofu init -backend-config="bucket=<gcs-bucket>" -backend-config="prefix=<state-prefix>"
tofu validate
tofu plan
```

Do not run `tofu apply` unless explicitly intended for the bootstrap step.

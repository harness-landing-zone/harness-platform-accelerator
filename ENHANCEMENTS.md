# Harness Platform Accelerator Enhancements

This document tracks the enhancements made to the Harness Platform Accelerator codebase.

## Date: 2026-05-26

### 1. Enhanced Service Resource (`modules/harness-resources/harness_service.tf`)

#### Changes Made:
- **Multi-scope support**: Services can now be created at **account, organization, or project** scope
  - Account-level services: Shared across all orgs and projects
  - Organization-level services: Shared across all projects in the org
  - Project-level services: Specific to individual projects
  
- **Split inline vs Git-synced services** into separate resources for clearer management
- **Inline services** (`harness_platform_service.inline_services`):
  - Service definition provided directly in YAML via the `yaml` field
  - Suitable for simple services or when Git sync is not required
  - Added `force_delete` support
  - Available at all scope levels
  
- **Git-synced services** (`harness_platform_service.git_services`):
  - Service definition stored in Git repository and synced via connector
  - Enables GitOps workflow with version control
  - Automatic dependency on connectors (git, AWS, GCP)
  - Lifecycle `ignore_changes` for `yaml` to prevent drift from Git
  - Available at all scope levels
  - Supports `git_details` configuration:
    - `store_type`: REMOTE (default)
    - `connector_ref`: Git connector reference
    - `repo_name`: Repository name (for account/org connectors)
    - `file_path`: Path to service YAML in repository
    - `branch`: Branch to sync from (optional)

#### Scope Architecture (`locals-merge.tf`):
- Moved services from `project_categories` to new `service_categories`
- Services are now available at all scope levels (account/org/project)
- Proper `org_id` and `project_id` handling via `local.resolved_org_id` and `local.resolved_project_id`

#### Benefits:
- **Multi-tenancy support**: Shared services at account/org level reduce duplication
- Clear separation of concerns between inline and Git-based services
- GitOps-ready with proper lifecycle management
- Better dependency tracking with connector modules
- Prevents configuration drift for Git-synced services
- Enables service reuse across organizational boundaries

### 2. Service Examples Created

Created comprehensive service YAML examples across all scope levels:

**Account-level services** (`harness-platform-deployment/account-config/services/`):
1. **shared-platform-service.yaml**
   - Account-scoped shared service
   - Available to all organizations and projects
   - Platform component versioning
   - Environment input variables

**Organization-level services** (`harness-platform-deployment/org-default-config/services/`):
1. **org-shared-service.yaml**
   - Organization-scoped shared service
   - Available to all projects in the org
   - Org-specific Docker connector reference
   - Organization identifier variable

**Project-level services** (`harness-platform-deployment/project-default-config/services/`):
1. **example-kubernetes-service.yaml**
   - Kubernetes service with inline manifest definition
   - Docker artifact source configuration
   - Service variables (replicas, namespace)
   - Harness manifest store

2. **example-git-service.yaml**
   - Git-synced service definition
   - Remote store configuration
   - Branch-based sync

3. **example-native-helm-service.yaml**
   - Native Helm chart deployment
   - HTTP Helm repository store
   - Helm version configuration (V3)
   - Values override examples

### 3. GCP Cloud Connector Support

#### Added GCP connector module instantiation in `modules/harness-resources/harness_cloud_connectors.tf`:
- `module.gcp_cloud_provider_connector` for GCP connectors
- Filters connectors by `type: gcp`
- Supports three authentication methods:
  1. **OIDC (Workload Identity Federation)** - Recommended for GKE
  2. **Manual (Service Account Key)** - JSON key-based auth
  3. **Inherit from Delegate** - Uses delegate's attached service account
- Enforces exactly one auth method via lifecycle precondition

#### Created GCP connector examples:
1. **gcp-oidc-connector.yaml**
   - Workload Identity Federation setup
   - Workload pool and provider configuration
   - Service account email binding

2. **gcp-manual-connector.yaml**
   - Service account key authentication
   - Secret reference pattern

3. **gcp-delegate-connector.yaml**
   - Delegate-based authentication
   - Minimal configuration for GKE environments

### 4. Documentation Enhancements

#### README.md Updates:
- Added comprehensive **Services** section with:
  - Inline service examples (Kubernetes)
  - Git-synced service configuration
  - Native Helm service examples
  - Complete list of supported service types:
    - Kubernetes, NativeHelm, ServerlessAwsLambda
    - AzureWebApp, ECS, SSH, WinRM
  - Service fields reference table
  
- Added **GCP Connector** documentation:
  - Three authentication methods with examples
  - Configuration patterns for each auth type
  - Integration with existing AWS connector docs

#### CLAUDE.md Enhancements:
- Added **Harness Platform Resources Used** section
- Categorized all resources by function:
  - Core Platform, RBAC, Governance, Connectors, Environments, CD/IACM
- Added **Resource Implementation Patterns**:
  - Standard resource pattern template
  - Scope-gated resources explanation
  - Git-imported pipeline pattern
  - Connector authentication patterns (AWS & GCP)
- Added **Service Account Connector Pattern** note
- Created **Adding New Harness Resource Types** guide:
  - 5-step process with code examples
  - Proper scope determination
  - locals-merge.tf integration
  - Resource file structure
  - YAML schema documentation

## Architecture Improvements

### Separation of Concerns
- Clear distinction between inline and Git-synced resources
- Better dependency management with explicit module references
- Lifecycle policies that prevent configuration drift

### Extensibility
- Template-based examples for all service types
- Modular connector architecture (AWS, GCP)
- Easy addition of new cloud providers following established patterns

### GitOps Readiness
- Git-synced services with proper lifecycle management
- Branch-based configuration management
- Connector-based repository integration

## Files Modified

1. `modules/harness-resources/harness_service.tf` - Enhanced service resource with multi-scope support
2. `modules/harness-resources/locals-merge.tf` - Moved services to separate category for all scopes
3. `modules/harness-resources/harness_cloud_connectors.tf` - Added GCP support
4. `README.md` - Added services and GCP connector documentation with scope examples
5. `CLAUDE.md` - Added comprehensive resource and pattern documentation with scope details

## Files Created

**Service Examples:**
1. `harness-platform-deployment/account-config/services/shared-platform-service.yaml`
2. `harness-platform-deployment/org-default-config/services/org-shared-service.yaml`
3. `harness-platform-deployment/project-default-config/services/example-kubernetes-service.yaml`
4. `harness-platform-deployment/project-default-config/services/example-git-service.yaml`
5. `harness-platform-deployment/project-default-config/services/example-native-helm-service.yaml`

**GCP Connector Examples:**
6. `harness-platform-deployment/org-default-config/cloud-provider-connectors/gcp-oidc-connector.yaml`
7. `harness-platform-deployment/org-default-config/cloud-provider-connectors/gcp-manual-connector.yaml`
8. `harness-platform-deployment/org-default-config/cloud-provider-connectors/gcp-delegate-connector.yaml`

**Documentation:**
9. `ENHANCEMENTS.md` - This file

## Next Steps (Recommendations)

1. **Add Azure Connector Support**
   - Similar pattern to AWS/GCP
   - Service principal and managed identity auth

2. **Add Docker/Artifact Registry Connectors**
   - Docker Registry connector
   - GCR, ECR, ACR connectors
   - Artifact sources for services

3. **Enhance Pipeline Support**
   - Pipeline templates
   - Input sets
   - Pipeline triggers

4. **Add Infrastructure Definitions**
   - Kubernetes clusters
   - VM infrastructure
   - Serverless infrastructure

5. **Add Monitoring/Notification Resources**
   - `harness_platform_monitored_service`
   - `harness_platform_notification_rule`
   - Integration with monitoring tools

6. **Add Variable/Secret Management**
   - Variable sets
   - Secret managers (Vault, AWS Secrets Manager)
   - File secrets

7. **Testing Infrastructure**
   - Terraform validation tests
   - YAML schema validation
   - Integration tests with Harness API

## Usage Examples

### Creating an Account-Level Service (Shared)

```yaml
# In harness-platform-deployment/account-config/services/platform-service.yaml
---
name: "Platform Service"
description: "Shared across all orgs and projects"
tags:
  scope: account
  shared: "true"

yaml:
  service:
    name: Platform Service
    identifier: platform_service
    serviceDefinition:
      type: Kubernetes
      spec:
        manifests:
          - manifest:
              identifier: platform_manifest
              type: K8sManifest
              spec:
                store:
                  type: Harness
                  spec:
                    files:
                      - /platform/deployment.yaml
```

### Creating an Organization-Level Service

```yaml
# In platform-configs/organizations/<org>/services/org-service.yaml
---
name: "Organization Service"
description: "Shared across all projects in this org"
tags:
  scope: organization
  team: platform

yaml:
  service:
    name: Organization Service
    identifier: org_service
    serviceDefinition:
      type: Kubernetes
      spec:
        manifests:
          - manifest:
              identifier: org_manifest
              type: K8sManifest
              spec:
                store:
                  type: Harness
                  spec:
                    files:
                      - /org/deployment.yaml
```

### Creating a Project-Level Service

```yaml
# In platform-configs/organizations/<org>/projects/<project>/services/my-app.yaml
---
name: "My Application"
tags:
  team: backend
  env: production

yaml:
  service:
    name: My Application
    identifier: my_application
    serviceDefinition:
      type: Kubernetes
      spec:
        manifests:
          - manifest:
              identifier: k8s_manifest
              type: K8sManifest
              spec:
                store:
                  type: Harness
                  spec:
                    files:
                      - /k8s/deployment.yaml
```

### Creating a Git-Synced Service (Any Scope)

```yaml
# Can be placed at account/org/project level
---
name: "My GitOps Application"
tags:
  team: platform
  sync: git

git_details:
  store_type: REMOTE
  connector_ref: org.github_connector
  repo_name: my-org/services
  file_path: harness/services/my-app.yaml
  branch: main
```

### Creating a GCP Connector

```yaml
# In platform-configs/organizations/<org>/cloud-provider-connectors/gcp-production.yaml
---
type: gcp
name: "GCP Production"
tags:
  env: production

oidc_authentication:
  workload_pool_id: "projects/123/locations/global/workloadIdentityPools/prod"
  provider_id: "harness"
  gcp_project_id: "my-prod-project"
  service_account_email: "harness@my-prod-project.iam.gserviceaccount.com"
  delegate_selectors:
    - prod-gke-delegate
```

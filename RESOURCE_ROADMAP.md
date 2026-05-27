# Harness Platform Accelerator - Resource Roadmap

This document outlines the priority roadmap for adding additional Harness platform resources to the accelerator.

## Current Resources (✅ Implemented)

### Core Platform
- ✅ `harness_platform_organization`
- ✅ `harness_platform_project`

### RBAC & Access Control
- ✅ `harness_platform_roles`
- ✅ `harness_platform_resource_group`
- ✅ `harness_platform_usergroup`
- ✅ `harness_platform_role_assignments`

### Governance & Policy
- ✅ `harness_platform_policy`
- ✅ `harness_platform_policyset`

### Connectors
- ✅ `harness_platform_connector_github`
- ✅ `harness_platform_connector_git`
- ✅ `harness_platform_connector_aws`
- ✅ `harness_platform_connector_gcp`

### Environments & Secrets
- ✅ `harness_platform_environment`
- ✅ `harness_platform_overrides`
- ✅ `harness_platform_secret_text`
- ✅ `harness_platform_secret_file`

### CD/IACM Resources
- ✅ `harness_platform_service` (account/org/project)
- ✅ `harness_platform_pipeline` (project-only, Git-imported)
- ✅ `harness_platform_workspace` (project-only)

---

## 🔥 High Priority (Next Sprint)

### 1. Infrastructure Definitions ⭐⭐⭐
**Resource**: `harness_platform_infrastructure`

**Why Critical**: Required for CD deployments. Links services to actual infrastructure.

**Scope**: Account, Org, Project

**Types to Support**:
- Kubernetes (direct cluster connection)
- Kubernetes GCP/AWS/Azure (cloud-specific)
- SSH/WinRM (traditional VMs)
- PDC (Physical Data Center)
- Azure Web Apps
- AWS Lambda
- AWS ECS
- Serverless.com

**Example Use Cases**:
```yaml
# Kubernetes infrastructure
type: KubernetesDirect
connector_ref: account.k8s_connector
namespace: <+input>
release_name: <+service.name>

# SSH infrastructure
type: SshWinRmAzure
connector_ref: org.azure_connector
host_filter:
  type: Tags
  spec:
    tags:
      environment: production
```

**Implementation Priority**: 🔴 **CRITICAL** - Blocks CD pipeline execution

---

### 2. Container Registry Connectors ⭐⭐⭐
**Resources**:
- `harness_platform_connector_docker`
- `harness_platform_connector_ecr` (AWS)
- `harness_platform_connector_gcr` (GCP)
- `harness_platform_connector_acr` (Azure)

**Why Critical**: Services need artifact sources. Docker images are primary deployment artifact.

**Scope**: Account, Org, Project

**Auth Methods**:
- **Docker Registry**: Username/password, anonymous
- **ECR**: AWS auth (OIDC, IRSA, manual, inherit)
- **GCR**: GCP auth (OIDC, service account, inherit)
- **ACR**: Azure auth (service principal, managed identity)

**Implementation Priority**: 🔴 **CRITICAL** - Required for artifact deployment

---

### 3. Azure Connector ⭐⭐⭐
**Resource**: `harness_platform_connector_azure`

**Why Important**: Third major cloud provider (completes AWS/GCP/Azure trio)

**Scope**: Account, Org, Project

**Auth Methods**:
- Service Principal (client ID + secret)
- Managed Identity (for Azure-hosted delegates)
- Certificate-based auth

**Implementation Priority**: 🟠 **HIGH** - Multi-cloud completeness

---

### 4. Variables & Configuration ⭐⭐
**Resources**:
- `harness_platform_variables`
- `harness_platform_variable_set`

**Why Important**: Centralized configuration management across scopes

**Scope**: Account, Org, Project

**Variable Types**:
- String
- Number
- Secret (reference to secret)

**Use Cases**:
```yaml
# Account-level defaults
variables:
  - name: company_domain
    type: String
    value: "mycompany.com"
  
  - name: default_region
    type: String
    value: "us-east-1"

# Variable sets (grouped variables)
variable_set:
  name: "Production Config"
  variables:
    - name: api_url
      value: "https://api.prod.mycompany.com"
```

**Implementation Priority**: 🟠 **HIGH** - Improves configuration management

---

### 5. Service Accounts & API Keys ⭐⭐
**Resources**:
- `harness_platform_service_account`
- `harness_platform_apikey`
- `harness_platform_token`

**Why Important**: Automation, CI/CD integration, programmatic access

**Scope**: Account, Org, Project

**Use Cases**:
- CI/CD pipeline integration
- Terraform automation
- External system integration
- Delegate authentication

**Implementation Priority**: 🟠 **HIGH** - Enables automation

---

## 🟡 Medium Priority (Next Quarter)

### 6. Templates ⭐⭐
**Resource**: `harness_platform_template`

**Types**:
- Pipeline templates
- Stage templates
- Step templates
- Step group templates

**Scope**: Account, Org, Project

**Why Useful**: Standardize pipeline patterns, reduce duplication

**Implementation Priority**: 🟡 **MEDIUM** - Improves consistency

---

### 7. Input Sets ⭐⭐
**Resource**: `harness_platform_input_set`

**Why Useful**: Parameterize pipelines for different environments

**Scope**: Project (linked to specific pipeline)

**Example**:
```yaml
input_set:
  name: "Production Inputs"
  pipeline_identifier: "deploy_app"
  inputs:
    environment: production
    replicas: 5
    namespace: prod
```

**Implementation Priority**: 🟡 **MEDIUM** - Enhances pipeline flexibility

---

### 8. Triggers ⭐⭐
**Resource**: `harness_platform_triggers`

**Types**:
- Webhook triggers (Git push, PR, etc.)
- Scheduled/Cron triggers
- Manifest triggers
- Artifact triggers

**Scope**: Project

**Why Useful**: Automate pipeline execution

**Implementation Priority**: 🟡 **MEDIUM** - Enables automation

---

### 9. Kubernetes Cluster Connector ⭐⭐
**Resource**: `harness_platform_connector_kubernetes`

**Auth Methods**:
- Service Account
- Username/Password
- Client Key/Cert
- OIDC
- Delegate in-cluster

**Why Useful**: Direct cluster connectivity for K8s deployments

**Implementation Priority**: 🟡 **MEDIUM** - Alternative to cloud connectors

---

### 10. File Store ⭐
**Resources**:
- `harness_platform_file_store_file`
- `harness_platform_file_store_folder`

**Why Useful**: Store scripts, configs, manifests in Harness

**Scope**: Account, Org, Project

**Implementation Priority**: 🟡 **MEDIUM** - Useful for script storage

---

### 11. Notification Rules ⭐
**Resource**: `harness_platform_notification_rule`

**Channels**:
- Slack
- Email
- PagerDuty
- Microsoft Teams
- Webhook

**Events**:
- Pipeline success/failure
- Approval needed
- Deployment freeze

**Implementation Priority**: 🟡 **MEDIUM** - Improves observability

---

## 🔵 Lower Priority (Future)

### 12. Monitored Services & SRM
**Resources**:
- `harness_platform_monitored_service`
- `harness_platform_slo`

**Why Lower Priority**: Requires Service Reliability Management setup

**Scope**: Project

---

### 13. GitOps Resources
**Resources**:
- `harness_platform_gitops_agent`
- `harness_platform_gitops_cluster`
- `harness_platform_gitops_repository`
- `harness_platform_gitops_applications`

**Why Lower Priority**: GitOps is a specialized workflow

**Scope**: Account, Project

---

### 14. Freeze Windows
**Resource**: `harness_platform_freeze`

**Why Lower Priority**: Governance feature for mature teams

**Use Cases**:
- Holiday deployment freezes
- Change management windows
- Scheduled maintenance blocks

---

### 15. Artifact Connectors (Additional)
**Resources**:
- `harness_platform_connector_artifactory`
- `harness_platform_connector_nexus`
- `harness_platform_connector_github_packages`

**Why Lower Priority**: Less common than Docker registries

---

### 16. Feature Flags (FF Module)
**Resources**:
- `harness_platform_feature_flag`
- `harness_platform_feature_flag_target`
- `harness_platform_feature_flag_target_group`

**Why Lower Priority**: Requires Feature Flags module

---

### 17. Cloud Cost Management
**Resources**:
- `harness_platform_ccm_filters`
- `harness_platform_autostopping_rule`

**Why Lower Priority**: Requires CCM module

---

## 📊 Recommended Implementation Order

### Phase 1: Essential CD Components (Week 1-2)
1. ✅ Infrastructure definitions (Kubernetes, SSH, cloud-specific)
2. ✅ Docker registry connector
3. ✅ ECR/GCR/ACR connectors
4. ✅ Azure connector

**Outcome**: Full CD capability across all major clouds

---

### Phase 2: Configuration & Automation (Week 3-4)
5. ✅ Variables & Variable Sets
6. ✅ Service Accounts & API Keys
7. ✅ Kubernetes cluster connector

**Outcome**: Proper configuration management and automation

---

### Phase 3: Pipeline Enhancement (Week 5-6)
8. ✅ Templates (pipeline, stage, step)
9. ✅ Input Sets
10. ✅ Triggers (webhook, cron, artifact)

**Outcome**: Reusable patterns and automated execution

---

### Phase 4: Observability & Governance (Week 7-8)
11. ✅ Notification Rules
12. ✅ File Store
13. ✅ Freeze Windows

**Outcome**: Production-ready governance and alerting

---

### Phase 5: Advanced Features (Future)
14. ⏳ GitOps resources
15. ⏳ Monitored Services & SLOs
16. ⏳ Additional artifact connectors
17. ⏳ Feature Flags
18. ⏳ Cloud Cost Management

**Outcome**: Advanced platform capabilities

---

## 🎯 Quick Wins (Can be done in parallel)

These resources are simpler and can be added alongside major features:

1. **Filters** - `harness_platform_filter` (saved UI filters)
2. **Tags** - Better tag management utilities
3. **Dashboards** - `harness_platform_dashboard` (custom dashboards)
4. **Secrets Management Connectors**:
   - Vault
   - AWS Secrets Manager
   - GCP Secret Manager
   - Azure Key Vault

---

## 💡 Implementation Patterns to Establish

For each new resource, follow this pattern:

1. **Module file**: `modules/harness-resources/harness_<resource>.tf`
2. **Category**: Add to appropriate category in `locals-merge.tf`
3. **Examples**: Create YAML examples for each scope level
4. **Documentation**: Update README.md with YAML schema
5. **Tests**: Add validation and example tests

---

## 🤝 Community Priorities

If you have specific use cases or resources you need, prioritize accordingly:

- **Multi-cloud deployments** → Infrastructure + Cloud connectors
- **Container-based apps** → Docker/Container registry connectors
- **GitOps workflows** → GitOps resources
- **Compliance/governance** → Freeze windows, policies
- **Cost optimization** → CCM resources
- **Feature management** → Feature Flag resources

---

## 📝 Notes

- Resources marked with ⭐⭐⭐ are critical for core CD functionality
- Resources marked with ⭐⭐ significantly improve platform usability
- Resources marked with ⭐ are nice-to-have enhancements
- Implementation priority considers both value and complexity
- Some resources require specific Harness modules to be enabled

---

**Last Updated**: 2026-05-26  
**Current PR**: #1 (Services + GCP connectors)  
**Next Target**: Infrastructure + Container Registry Connectors

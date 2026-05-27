# Terraform Agent for Harness Platform Accelerator

An AI-powered agent that generates Terraform/OpenTofu configuration files from natural language prompts, following the architecture patterns defined in CLAUDE.md.

## Features

- **Natural Language Input**: Describe infrastructure in plain English
- **Multi-Scope Support**: Automatically determines account/org/project scope
- **Pattern Compliance**: Generates files following established repo conventions
- **Dry Run Mode**: Preview changes before writing files
- **Context Aware**: Uses existing configuration structure for consistency

## Installation

```bash
# Install dependencies
pip install -r requirements.txt

# Set your Anthropic API key
export ANTHROPIC_API_KEY="sk-ant-..."

# Make executable
chmod +x terraform-agent.py
```

## Usage

### Dry Run (Preview Only)

```bash
python terraform-agent.py "Create a new organization called DevOps Team"
```

### Apply Changes

```bash
python terraform-agent.py --apply "Add a GCP connector for project cloud-infra"
```

## Examples

### Create Organization

```bash
python terraform-agent.py "Create organization Platform Engineering with admin and developer groups"
```

Generates:
- `platform-configs/organizations/Platform Engineering/config.yaml`
- `platform-configs/organizations/Platform Engineering/groups/admins.yaml`
- `platform-configs/organizations/Platform Engineering/groups/developers.yaml`

### Add Cloud Connector

```bash
python terraform-agent.py "Add AWS connector with IRSA auth to org DevOps using delegate prod-delegate"
```

Generates:
- `platform-configs/organizations/DevOps/cloud-provider-connectors/aws-prod.yaml`

### Create Project Environment

```bash
python terraform-agent.py "Add production environment to project backend-services in org Platform Team"
```

Generates:
- `platform-configs/organizations/Platform Team/projects/backend-services/environments/production.yaml`

### Create CD Service

```bash
python terraform-agent.py "Create a Kubernetes service at organization level for nginx deployment"
```

Generates:
- `platform-configs/organizations/<org-name>/services/nginx.yaml`

### Add IACM Workspace

```bash
python terraform-agent.py "Create IACM workspace for GCP infrastructure in project cloud-ops"
```

Generates:
- `platform-configs/organizations/<org-name>/projects/cloud-ops/workspaces/gcp-infra.yaml`

## Output Format

The agent provides:

1. **Analysis**: What will be created and at what scope
2. **Files**: Complete file paths and YAML content
3. **Commands**: Exact Terraform/OpenTofu commands to run
4. **Notes**: Validation steps or manual actions required

## Supported Resource Types

- Organizations
- Projects
- Groups (User Groups)
- Roles (Custom RBAC roles)
- Resource Groups
- Environments
- Policies (OPA/Rego)
- Policy Sets
- Git Connectors (GitHub, GitLab, Bitbucket)
- Cloud Connectors (AWS, GCP)
- Services (CD service definitions - any scope)
- Pipelines (CD/CI pipelines - project scope)
- Workspaces (IACM - project scope)
- Secrets (Text and File)

## Architecture Patterns

The agent follows these conventions from CLAUDE.md:

### Identifier Derivation
- Lowercase transformation
- Spaces → underscores
- Dashes → underscores
- Override with explicit `identifier:` in YAML

### Template Merging
- Global templates: `templates/<category>/`
- Scope overrides: `platform-configs/organizations/<org>/<category>/`

### Scope-Gated Resources
- **Account**: Baseline setup (bootstrap module)
- **Organization**: Groups, roles, resource groups, connectors, services
- **Project**: Environments, workspaces, pipelines, services

### Multi-Scope Services
The agent supports creating CD services at any scope:
- **Account-level**: `harness-platform-bootstrap/services/`
- **Organization-level**: `platform-configs/organizations/<org>/services/`
- **Project-level**: `platform-configs/organizations/<org>/projects/<project>/services/`

### Authentication Patterns

**AWS Connectors** (4 methods):
- OIDC (recommended for EKS)
- IRSA (in-cluster delegates)
- Manual (access key/secret)
- Inherit from delegate

**GCP Connectors**:
- Service Account Key
- Inherit from delegate
- Workload Identity (GKE)

**Git Connectors**:
- GitHub App (recommended)
- Personal Access Token
- SSH Key

## Workflow

1. Run agent with prompt
2. Review generated files (dry run)
3. Add `--apply` to write files
4. Navigate to appropriate directory
5. Run Terraform/OpenTofu commands
6. Verify in Harness UI

```bash
# Example workflow
python terraform-agent.py "Create org Platform with admin group"
python terraform-agent.py --apply "Create org Platform with admin group"

cd harness-platform-deployment
tofu plan -var="scope_level=organization" -var="organization_name=Platform"
tofu apply
```

## Advanced Usage

### Custom API Key

```bash
python terraform-agent.py --api-key "sk-ant-..." "your prompt"
```

### Chaining Operations

```bash
# Create org
python terraform-agent.py --apply "Create org DevOps"

# Add project
python terraform-agent.py --apply "Add project backend-api to org DevOps"

# Add resources
python terraform-agent.py --apply "Add production environment to project backend-api"
```

## Limitations

- Does not execute Terraform commands (you must run manually)
- Does not validate against Harness API (use `tofu validate`)
- Does not handle complex template merging logic (follows simple override pattern)
- Requires manual verification of generated YAML syntax

## Troubleshooting

**API Key Error**
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

**Invalid YAML**
- Review generated files in dry run mode
- Validate with `yamllint` before applying

**Terraform Errors**
- Run `tofu validate` after generation
- Check `tofu plan` output before applying
- Review CLAUDE.md for resource-specific patterns

## Next Steps

After generating files:

1. **Validate**: Run `tofu validate` in appropriate directory
2. **Plan**: Run `tofu plan` with correct scope variables
3. **Review**: Check plan output for expected resources
4. **Apply**: Run `tofu apply` after confirmation
5. **Verify**: Check Harness UI for created resources

## Contributing

When adding new resource type support:

1. Update system prompt with resource patterns
2. Add example prompts to this README
3. Test with dry run and apply modes
4. Document any special handling required

## References

- [CLAUDE.md](./CLAUDE.md) - Full architecture documentation
- [Harness Provider Docs](https://registry.terraform.io/providers/harness/harness/latest/docs)
- [OpenTofu Documentation](https://opentofu.org/docs/)

# Resource Priority Matrix

Quick reference for what to build next based on your use case.

## 🎯 Priority Matrix

```
                    HIGH IMPACT
                         ↑
    ┌────────────────────┼────────────────────┐
    │                    │                    │
    │   🟢 QUICK WINS    │   🔴 CRITICAL      │
    │                    │                    │
L   │  • Variables       │  • Infrastructure  │
O   │  • K8s Connector   │  • Docker Registry │
W   │  • File Store      │  • ECR/GCR/ACR     │
    │  • Notifications   │  • Azure Connector │
C   ├────────────────────┼────────────────────┤
O   │                    │                    │
M   │  🔵 NICE TO HAVE   │  🟡 IMPORTANT      │
P   │                    │                    │
L   │  • GitOps          │  • Templates       │
E   │  • Monitored Svcs  │  • Input Sets      │
X   │  • Feature Flags   │  • Triggers        │
I   │  • CCM             │  • Service Accts   │
T   │                    │                    │
Y   └────────────────────┼────────────────────┘
    ↓                    │
                    LOW IMPACT
```

## 📋 Top 5 Resources to Add Next

### 1. 🥇 Infrastructure Definitions
**Impact**: 🔴 CRITICAL - Blocks CD deployments  
**Complexity**: 🟡 Medium  
**Effort**: 2-3 days  

```yaml
infrastructure:
  type: KubernetesDirect
  connector_ref: account.k8s_connector
  namespace: production
  release_name: <+service.name>
```

**Why First**: Without infrastructure, you can't deploy services to actual environments.

---

### 2. 🥈 Docker Registry Connectors
**Impact**: 🔴 CRITICAL - Required for artifacts  
**Complexity**: 🟢 Low  
**Effort**: 1 day  

```yaml
type: docker
connector_url: https://index.docker.io/v2/
authentication:
  username: myuser
  password_ref: account.dockerhub_token
```

**Why Second**: Services need artifacts to deploy. Docker is most common.

---

### 3. 🥉 ECR/GCR/ACR Connectors
**Impact**: 🔴 CRITICAL - Multi-cloud artifacts  
**Complexity**: 🟡 Medium  
**Effort**: 2 days  

```yaml
# ECR
type: ecr
region: us-east-1
oidc_authentication:
  iam_role_arn: arn:aws:iam::123:role/HarnessECR

# GCR  
type: gcr
gcp_project_id: my-project
oidc_authentication: {...}

# ACR
type: acr
subscription_id: abc-123
service_principal: {...}
```

**Why Third**: Cloud-native registries are standard in cloud deployments.

---

### 4. 🏅 Azure Connector
**Impact**: 🟠 HIGH - Multi-cloud completeness  
**Complexity**: 🟡 Medium  
**Effort**: 1-2 days  

```yaml
type: azure
authentication:
  type: service_principal
  client_id: abc-123
  tenant_id: def-456
  secret_ref: account.azure_client_secret
```

**Why Fourth**: Completes the AWS/GCP/Azure trio for multi-cloud.

---

### 5. 🎖️ Variables & Variable Sets
**Impact**: 🟠 HIGH - Configuration management  
**Complexity**: 🟢 Low  
**Effort**: 1 day  

```yaml
variables:
  - name: api_url
    type: String
    value: https://api.mycompany.com
  
  - name: db_password
    type: Secret
    value: account.db_password
```

**Why Fifth**: Centralizes configuration, reduces duplication.

---

## 🎯 Use Case Based Priorities

### If You're Building: **Container Deployments (Kubernetes)**
1. ✅ Infrastructure (KubernetesDirect)
2. ✅ Docker Registry Connector
3. ✅ ECR/GCR connectors
4. ✅ K8s Cluster Connector
5. ⏸️ Templates (for standardization)

**Estimated Time**: 1 week

---

### If You're Building: **Multi-Cloud Platform**
1. ✅ Infrastructure (all types)
2. ✅ Azure Connector
3. ✅ All container registries (ECR/GCR/ACR)
4. ✅ Variables & Variable Sets
5. ⏸️ Notification Rules

**Estimated Time**: 2 weeks

---

### If You're Building: **Traditional VM Deployments**
1. ✅ Infrastructure (SSH/WinRM)
2. ✅ Artifact connectors (Artifactory/Nexus)
3. ✅ Variables
4. ✅ Service Accounts
5. ⏸️ Freeze Windows

**Estimated Time**: 1.5 weeks

---

### If You're Building: **Serverless Applications**
1. ✅ Infrastructure (AWS Lambda, Azure Functions)
2. ✅ AWS/Azure/GCP connectors
3. ✅ ECR/GCR/ACR connectors
4. ✅ Variables
5. ⏸️ Triggers (for event-driven)

**Estimated Time**: 1.5 weeks

---

### If You're Building: **GitOps Platform**
1. ✅ Infrastructure (Kubernetes)
2. ✅ GitOps Agent
3. ✅ GitOps Cluster
4. ✅ GitOps Repository
5. ✅ GitOps Applications

**Estimated Time**: 2 weeks

---

## 🚀 Fast Track (MVP in 1 Week)

To get a **minimal viable CD platform** running:

### Day 1-2: Infrastructure
- `harness_platform_infrastructure`
- Kubernetes + SSH types
- Examples for common patterns

### Day 3-4: Container Registries
- `harness_platform_connector_docker`
- `harness_platform_connector_ecr`
- `harness_platform_connector_gcr`

### Day 5: Azure Support
- `harness_platform_connector_azure`
- Service principal auth

### Day 6-7: Configuration & Testing
- `harness_platform_variables`
- Integration testing
- Documentation

**Result**: Full CD capability for K8s + VMs across AWS/GCP/Azure ✅

---

## 📊 Complexity vs Impact Analysis

```
HIGH COMPLEXITY
      ↑
      │  GitOps Resources         Templates
      │  (Multi-part)             (Complex versioning)
      │          
      │                  Infrastructure
      │                  (Many types)
      │
      │  Monitored Svcs            Azure/ACR
      │  (SRM dependency)          (Auth patterns)
      │              
      │                  Triggers            Variables
      │                  (Many types)        (Simple)
      │
      │  Feature Flags              Docker Connector
      │  (FF module)                (Standard)
      │
      └──────────────────────────────────────────→
   LOW IMPACT                          HIGH IMPACT
```

## 🎁 Bonus: Quick Wins (< 1 day each)

These can be built quickly and add immediate value:

1. **Kubernetes Cluster Connector** (4 hours)
   - Simple auth patterns
   - Commonly used

2. **Variables** (3 hours)
   - Straightforward implementation
   - High reuse value

3. **Docker Registry Connector** (3 hours)
   - Simple auth (username/password)
   - Universal need

4. **File Store** (4 hours)
   - Basic CRUD operations
   - Useful for scripts

5. **Notification Rules** (5 hours)
   - Standard webhook patterns
   - Improves observability

**Total Time**: ~2 days for 5 useful resources

---

## 🗓️ Suggested Sprint Planning

### Sprint 1 (Week 1-2): Core CD Infrastructure
- Infrastructure definitions ✅
- Docker/ECR/GCR connectors ✅
- Azure connector ✅
- **Deliverable**: Deploy containers to K8s/VMs

### Sprint 2 (Week 3-4): Configuration & Automation  
- Variables & Variable Sets ✅
- Service Accounts & API Keys ✅
- K8s Cluster Connector ✅
- **Deliverable**: Automated, configurable deployments

### Sprint 3 (Week 5-6): Pipeline Enhancement
- Templates ✅
- Input Sets ✅
- Triggers ✅
- **Deliverable**: Reusable, event-driven pipelines

### Sprint 4 (Week 7-8): Production Readiness
- Notification Rules ✅
- File Store ✅
- Freeze Windows ✅
- **Deliverable**: Production-grade platform

---

## 💡 Pro Tips

1. **Start with what blocks deployments**: Infrastructure first, then registries
2. **Build for your cloud**: If you're AWS-heavy, prioritize ECR. GCP? GCR first.
3. **Quick wins boost morale**: Add Variables and Docker connector early
4. **Templates can wait**: Get basic deployments working first
5. **Documentation matters**: Good examples = faster adoption

---

## 📞 Decision Helper

**"What should I build next?"**

Answer these questions:

1. **Can I deploy a service end-to-end?**
   - ❌ No → Build Infrastructure + Registries
   - ✅ Yes → Continue to #2

2. **Do I support my primary cloud provider?**
   - ❌ No → Build cloud connector (Azure/AWS/GCP)
   - ✅ Yes → Continue to #3

3. **Is configuration manageable?**
   - ❌ No → Build Variables + Variable Sets
   - ✅ Yes → Continue to #4

4. **Are pipelines automated?**
   - ❌ No → Build Triggers + Service Accounts
   - ✅ Yes → Continue to #5

5. **Are there reusable patterns?**
   - ❌ No → Build Templates + Input Sets
   - ✅ Yes → Build advanced features (GitOps, SRM, etc.)

---

**Next Recommended Action**: Start with Infrastructure Definitions (see RESOURCE_ROADMAP.md for implementation details)

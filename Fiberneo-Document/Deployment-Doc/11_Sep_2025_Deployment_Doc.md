# Fiberneo Deployment Guide

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Service Dependencies](#service-dependencies)
3. [Fiberneo-UI Deployment](#fiberneo-ui-deployment)
   - [Deployment Steps](#deployment-steps-ui)
     - [Step 1: Repository Setup (UI)](#step-1-repository-setup-ui)
     - [Step 2: Helm Chart Configuration (UI)](#step-2-helm-chart-configuration-ui)
     - [Step 3: Deploy Service (UI)](#step-3-deploy-service-ui)
   - [Service Configuration (UI)](#service-configuration-ui)
     - [Chart Configuration (UI)](#chart-configuration-ui)
     - [Templates Overview (UI)](#templates-overview-ui)
4. [Fiberneo-Backend Deployment](#fiberneo-backend-deployment)
   - [Deployment Steps](#deployment-steps-backend)
     - [Step 1: Repository Setup (Backend)](#step-1-repository-setup-backend)
     - [Step 2: Database Setup](#step-2-database-setup)
     - [Step 3: Secret Manager Configuration](#step-3-secret-manager-configuration)
     - [Step 4: Configure Secret Provider Service Account](#step-4-configure-secret-provider-service-account)
     - [Step 5: Helm Chart Configuration](#step-5-helm-chart-configuration)
     - [Step 6: Deploy Service](#step-6-deploy-service)
   - [Service Configuration (Backend)](#service-configuration-backend)
     - [Dependencies Configuration](#dependencies-configuration)
     - [Templates Overview (Backend)](#templates-overview-backend)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)
7. [Useful Commands](#useful-commands)
8. [Additional Notes](#additional-notes)


---

## Prerequisites

Before deploying, ensure the following prerequisites are met:

- ✅ **Kubernetes Cluster** is running and accessible
- ✅ **Helm** is installed and configured (v3.x)
- ✅ **Docker Registry** is accessible
- ✅ **Namespace `ansible`** is created
- ✅ For Backend: **Vault Secret Manager** is configured, **Crypto.zip** is available for decryption
- ✅ For UI: **Istio Gateway** is configured (for VirtualService)
- ✅ Required dependencies are deployed (see Service Dependencies)

---

## Service Dependencies

### Backend Dependencies

- Phase 1: Core Infrastructure (Required First)
  1. **apigw** - API Gateway
  2. **keycloak** - Identity and Access Management
  3. **base-utility** - Core utility services
- Phase 2: Data & Cache Layer (Required Second)
  4. **redis-stack-server** - Caching and session management
  5. **onesearch** - Search engine infrastructure (Global Search)
- Phase 3: Supporting Services
  6. **identity-management-service**
  7. **workflow-management-service**
  8. **form-builder-service**
  9. **vendor-service**
  10. **fiberneo-service**
  11. **analytics-service**
  12. **data-inside-service**
  13. **contract-service**
  14. **document-service**
  15. **sla-service**

### UI Dependencies

- Phase 1: Core Infrastructure (Required First)
  1. **keycloak** - Identity and Access Management
  2. **Core-UI-shell** - For shell access
  3. **UI-designer** - For `main.js` configuration, etc.

---

## Fiberneo-UI Deployment

### Deployment Steps {#deployment-steps-ui}

#### Step 1: Repository Setup {#step-1-repository-setup-ui}

```bash
# Clone the repository (if not already done)
git clone <your-repo-name>
cd <your-repo-name>

# Navigate to FIBERNEO UI service directory
cd fiberneo/ui/fiberneo/

# Verify directory structure
ls
# Expected output: Chart.yaml  configmapfiles/  templates/  values.yaml

# Verify Helm chart structure
ls templates/
# Expected output: confimap.yaml  deployment.yaml  hpa.yaml  service.yaml  virtualService.yaml  NOTES.txt  _helpers.tpl

# Verify configmap files
ls configmapfiles/
# Expected output: nginx.conf
```

#### Step 2: Helm Chart Configuration {#step-2-helm-chart-configuration-ui}

The FIBERNEO UI service Helm chart includes the following components:

- Chart.yaml
- values.yaml
- templates/
- configmapfiles/

##### Chart Configuration {#chart-configuration-ui}

```yaml
# values.yaml (key fields)
replicaCount: 1

image:
  repository: registry.visionwaves.com/fiberneo-ui
  tag: fiberneo-demo-17_v15_ui_demo
  pullPolicy: Always

service:
  type: ClusterIP
  name: fiberneo-ui
  port: 80
  targetPort: 8081

resourcesLimits:
  cpu: 100m
  memory: 200M
requestsResources:
  cpu: 10m
  memory: 100M

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 100
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80

livenessProbe:
  path: /nginx_status
  initialDelaySeconds: 80
  periodSeconds: 20
  failureThreshold: 3

readinessProbe:
  path: /nginx_status
  initialDelaySeconds: 30
  periodSeconds: 10

virtualService:
  enabled: true
  context: /fiberneo
  rewriteForSlash: false

gateway:
  enabled: true
  name: ingressgateway

configMap:
  createIndexhtmlConfigmap: false
  createkeycloakContextConfigmap: false
  createNginxconfConfigmap: true
  defaultMode: '0755'

exporter:
  enable: false
  name: nginx-exporter
  image:
    repository: nginx/nginx-prometheus-exporter
    pullPolicy: Always
    tag: 0.10.0
  env:
    SCRAPE_URI: http://localhost:8081/nginx_status
    NGINX_RETRIES: '10'
    TELEMETRY_PATH: /metrics
```

##### Templates Overview {#templates-overview-ui}

1. `deployment.yaml` - Main UI application deployment with Nginx
2. `service.yaml` - Kubernetes service for internal communication
3. `hpa.yaml` - Horizontal Pod Autoscaler for scaling (if enabled)
4. `confimap.yaml` - Nginx configuration files
5. `virtualService.yaml` - Istio VirtualService for routing
6. `NOTES.txt` - Post-deployment instructions

#### Step 3: Deploy Service {#step-3-deploy-service-ui}

```bash
# Verify current directory
pwd
# Should be: /path/to/visionwaves-deployment/fiberneo/ui/fiberneo

# Get service name from Chart.yaml
cat Chart.yaml
# Look for 'name' field: fiberneo-ui

# Review image configuration in values.yaml
grep -A 5 "image:" values.yaml
# image:
#   repository: registry.visionwaves.com/fiberneo-ui
#   tag: fiberneo-demo-17_v15_ui_demo
#   pullPolicy: Always

# Deploy service using Helm
helm upgrade fiberneo-ui -n ansible . --install

# Check deployment status
helm list -n ansible | grep fiberneo-ui
```

---

## Fiberneo-Backend Deployment

### Deployment Steps {#deployment-steps-backend}

#### Step 1: Repository Setup {#step-1-repository-setup-backend}

```bash
# Clone the repository (if not already done)
git clone <your-repo-name>
cd <your-repo-name>

# Navigate to fiberneo service directory
cd fiberneo/Backend

# Verify directory structure
ls
# Expected output: Chart.yaml  config/  templates/  values.yaml

# Verify Helm chart structure
ls templates/
# Expected output: configmap.yaml  deployment.yaml  hpa.yaml  service.yaml  serviceaccount.yaml  NOTES.txt  _helpers.tpl
```

#### Step 2: Database Setup {#step-2-database-setup}

```bash
# Backup existing DB (optional)
# mysqldump -u '' -p '' fiberneo > /path/to/FIBERNEO_BACKUP.sql

# 1. Get database dump or source file from the below path
# https://github.com/visionwaves/visionwaves-deployment/tree/demo/fiberneo/sql/database-docs

# 2. Download FIBERNEO_WITH_DATA.sql or FIBERNEO_WITHOUT_DATA.sql

# 3. Access mysql cluster in generated-app-db namespace using its admin mysql user
mysql -h <mysql-host> -P 3306 -u <username> -p

# 4. Create a database (if it does not already exist)
CREATE DATABASE IF NOT EXISTS FIBERNEO;

# 👉 If database already exists and you want a clean setup:
# DROP DATABASE fiberneo;
# CREATE DATABASE fiberneo;

# 5. Use the FIBERNEO database and source the downloaded file
USE FIBERNEO;
SOURCE /path/to/yourfolder/FIBERNEO_WITHOUT_DATA.sql;

# ⚠️ Troubleshooting:
# - If "ERROR 1049 (42000): Unknown database" → run `USE FIBERNEO;` first
# - If "ERROR 1064 (42000)" → check the SQL file path (use absolute path)
# - If permissions error → ensure you are logged in as admin user
# - If SOURCE still fails, run from shell instead of MySQL prompt:
#   mysql -u '' -p'' fiberneo < /path/to/FIBERNEO_WITHOUT_DATA.sql
```

#### Step 3: Secret Manager Configuration {#step-3-secret-manager-configuration}

1. Get svc of Vault from `vault` namespace and port-forward to 8200 to access the Vault UI.
2. Login with the username and token from the Vault Secret Manager.
3. Create secret in Vault Secret Manager with name: `fiberneo` (path `kv/data/fiberneo`). If it exists, verify and update values.
4. Important: Decrypt and update values before creating the secret.

**Setup crypto environment:**

```bash
# Unzip the Crypto.zip file
unzip Crypto.zip
cd Crypto/

# Export the E_C value from the secrets
export E_C="tso*****sWM=" # Your E_C valid key value
```

**Encrypt/decrypt required values:**

```bash
# encodeco.sh usage
# Encrypt: ./encodeco.sh e "VALUE_TO_BE_ENCRYPTED"
# Decrypt: ./encodeco.sh d "ENCODED_VALUE"

# Encrypt MYSQL_URL and IP address
./encodeco.sh e "jdbc:mysql://<MYSQL_HOST>:3306/FIBERNEO?useSSL=true"

# Encrypt database credentials
./encodeco.sh e "your_db_username"
./encodeco.sh e "your_db_password"
```

5. Create the secret with the following values:

```bash
# this is key use for encryption and decryption
export E_C="tso********sWM="

# Value for DB credentials
export MYSQL_URL="SQ36392E************QyfeWyN"
export db_user="hqvI*************XIcg=="
export db_user_pass="qawN*******xQ=="

# service-url to be added in Vault
export API_KEY="<********GOOGLE_API_KEY*************>"
export APP_NODE_URL="fVkPOSI8dStXfk2PdFbXkX9Pg38DvZCmS7j/idVa/PliIrFJkJAm1R6c5KR+v7sKPRGz8OsbYSkuEzB7wPWfAQ=="
export BASE_UTILITY="http://base-utility-service/base/util/rest"
export BPMN_CONFIGURATION="http://bpmn-bpmn-configuration-service/bpmnconfig/rest"
export CATALOG="http://catalogue-builder/cb/rest"
export CATALOG_BUILDER="http://catalogue-builder/catalogue/rest"
export CM_MICROSERVICE="http://cm-microservice-cm-service/cm/rest"
export CM_SERVICE_URL=""
export DOCUMENT_SERVICE="http://document-document-service/document-management/rest"
export FFM_SERVICE="http://field-force-mgmt-service/field-force-mgmt/rest"
export FIBERNEO_URL="http://fiberneo-service/fiberneo/rest"
export FORM_BUILDER="http://form-builder/fb/rest"
export HOSTNAME="f9fcdvwcJ8qC4bE2Ou9p8g=="
export IDENTITY_MANAGEMENT="http://identity-management-service/ipam-naming/rest"
export JAVAMELODY_STATUS="AAJN8G9/svXzcp1DiFkZxw=="
export KEYCLOAK_TOKEN="lqvWNqry3QLLfo5BqwkRUQ=="
export LCM_SERVICE="http://lcm-service-commissioning-service/lcm"
export MASTER="0suK27r6I8nIWCb3XmvYtw=="
export MASTER_AUTH="o58F2eAU9oFDJBLaXjMJGg=="
export MATERIAL_MANAGEMENT="http://material-management-service/material-management/rest"
export NOTIFICATION_MICROSERVICE="http://notification-microservice/platform/notification/rest"
export ONE_SEARCH="http://onesearch-service.ansible.svc.cluster.local/onesearch/rest"
export PORT="6gb72fviVHsBaR4G+sYyZQ=="
export REDIS_SERVER_URL="ROml+T6b57ee77bOBD4no7ww8Wxr/uN9pBeYmKw4YAY="
export SENITAL_ENABLE="lqvWNqry3QLLfo5BqwkRUQ=="
export SENITAL_LIST="BPK9l5HuBTE/Lnennp9MGo5uLmpK2WtHMvqG6naIUR7vvUZdP7hlC/efQGn25nHxovJD/l+lOi4FFcZNIJd8VQ=="
export SLA_SERVICE="http://sla-service.ansible.svc.cluster.local/sla/rest"
export WORKFLOW_ENGINE_REST="http://workflow-management-service/wfm/engine-rest"
export WORKFLOW_MGMT="http://workflow-workflow-mgmt/wfm/rest/"
export WORKFLOW_SERVICE_URL="http://workflow-workflow-mgmt/wfm/rest"
export enttribe="FV9u6yvdusYmbzvqLIeEBA=="
```

6. It creates a new secret and its role (`fiberneo-role`) and ACL policy; verify the service account (`fiberneo-sa`) is configured properly.

#### Step 4: Configure Secret Provider Service Account {#step-4-configure-secret-provider-service-account}

```bash
# 1. Go to the helm chart folder where values.yaml exists
# 2. Update the following values in the values.yaml file:

serviceAccount:
  create: false  # if already created else true
  annotations: {}
  name: fiberneo-sa

podAnnotations:
  vault.hashicorp.com/agent-pre-populate-only: 'true'
  prometheus.io/scrape: 'true'
  prometheus.io/path: /fiberneo/actuator/prometheus
  prometheus.io/scheme: http
  prometheus.io/port: '9019'
  vault.hashicorp.com/agent-inject: 'true'
  vault.hashicorp.com/agent-init-first: 'true'
  vault.hashicorp.com/role: fiberneo-role
  vault.hashicorp.com/agent-inject-secret-database-config.txt: kv/data/fiberneo
  vault.hashicorp.com/agent-inject-template-secrets.env: |
    {{- with secret "kv/data/fiberneo" -}}
    {{- range $key, $value := .Data.data -}}
    export {{$key}}="{{$value}}"
    {{- "\n" -}}
    {{- end }}
    {{- end }}

# 3. Check the following values in deployment.yaml file as service account name is mentioned in the values.yaml file or default service account is used:
spec:
  serviceAccountName: {{ if .Values.serviceAccount.create }}{{ .Values.serviceAccount.name }}{{ else }}fiberneo-sa{{ end }}

# 4. Apply the above file changes
```

#### Step 5: Helm Chart Configuration {#step-5-helm-chart-configuration}

The fiberneo service Helm chart includes the following components:

- Chart.yaml
- values.yaml
- templates: `deployment.yaml`, `service.yaml`, `hpa.yaml`, `configmap.yaml`, `serviceaccount.yaml`, `NOTES.txt`, `_helpers.tpl`

```yaml
# values.yaml (key fields)
replicaCount: 1

image:
  repository: registry.visionwaves.com/{Name According to You for Example: fiberneo-demo}
  tag: tag according to you for Example: v1.0.1
  pullPolicy: IfNotPresent

service:
  port: 80
  targetPort: 8081
  type: ClusterIP

resourcesLimits:
  cpu: 500m
  memory: 2Gi
requestsResources:
  cpu: 500m
  memory: 2Gi

autoscaling:
  enabled: true
  minReplicas: 1
  maxReplicas: 3
  targetCPUUtilizationPercentage: 75
  targetMemoryUtilizationPercentage: 75

livenessProbe:
  enable: true
  path: /fiberneo/rest/ping
  initialDelaySeconds: 300
  periodSeconds: 20
  failureThreshold: 3
  timeoutSeconds: 3

readinessProbe:
  path: /fiberneo/rest/ping
  initialDelaySeconds: 60
  periodSeconds: 10
  timeoutSeconds: 3

env:
  servicePort: 8081
  serviceContext: /fiberneo
  PORT: '8081'
  deploymentName: fiberneo-service
```

#### Step 6: Deploy Service {#step-6-deploy-service}

```bash
# Verify current directory
pwd
# Should be: /path/to/visionwaves-deployment/fiberneo/Backend

# Get service name from Chart.yaml
cat Chart.yaml
# Look for 'name' field

# Review image configuration in values.yaml
grep -A 5 "image:" values.yaml
# image:
#   repository: registry.visionwaves.com/fiberneo
#   tag: v1_service
#   pullPolicy: IfNotPresent

# Deploy service using Helm with image override (include tag)
# Note: Change the image repository and tag according to the image pushed in your registry
helm upgrade <service-name> -n ansible . --set image.repository=registry.visionwaves.com/fiberneo --set image.tag=v1_service

# Alternative: Deploy with custom image if needed
# helm upgrade fiberneo-service -n ansible . \
#   --set image.repository=your-registry.com/fiberneo \
#   --set image.tag=your-tag
```

### Service Configuration {#service-configuration-backend}

#### Dependencies Configuration {#dependencies-configuration}

The service connects to:

- **Database**: MariaDB/MySQL (encrypted connection)
- **Redis**: For caching and session management
- **Vault**: For secret management
- **APM**: For application monitoring
- **Other Services**: workflow-management, document-management, vendor-service

#### Templates Overview {#templates-overview-backend}

1. `deployment.yaml` - Main application deployment with sidecar container
2. `service.yaml` - Kubernetes service for internal communication
3. `hpa.yaml` - Horizontal Pod Autoscaler for scaling
4. `configmap.yaml` - Configuration files (`application.properties`, scripts)
5. `serviceaccount.yaml` - Service account for workload identity
6. `NOTES.txt` - Post-deployment instructions

---

## Verification

### Backend

#### 1. Check Pod Status
```bash
kubectl get pods -n ansible | grep fiberneo
# Expected: Running status ( should be like this running 3/3 or 4/4 depending on number of replicas)
# Example: fiberneo-service-7f9ddb4bc8-smttz    4/4     Running  0  4d21h
```

#### 2. Check Service Status
```bash
kubectl get svc -n ansible | grep fiberneo
# Expected: ClusterIP service on port 80
# fiberneo-service   ClusterIP  10.96.223.101  <none>  80/TCP
```

#### 3. Check Health Endpoint
```bash
# Port forward to test locally
kubectl port-forward -n ansible svc/fiberneo-service 8080:80

# Test health endpoint
curl http://localhost:8080/fiberneo/rest/ping
# Expected: 200 OK response
# Example: {"status":"success"}
```

#### 4. Check Logs
```bash
# Check if service started successfully or not
kubectl logs -n ansible -l app.kubernetes.io/name=fiberneo-service --tail=100 | grep "service started successfully"

kubectl logs -n ansible -l app.kubernetes.io/name=fiberneo-service --tail=100
# Check for any startup errors or connection issues
```

#### 5. Check HPA Status
```bash
kubectl get hpa -n ansible fiberneo-service
# Expected: HPA configured with CPU/Memory targets
# NAME               REFERENCE                        TARGETS                        MINPODS   MAXPODS   REPLICAS   AGE
# fiberneo-service   Deployment/fiberneo-service      <unknown>/75%, <unknown>/75%   1         3         1          1day
```

### UI

#### 1. Check Pod Status
```bash
kubectl get pods -n ansible | grep fiberneo-ui
# Expected: Running status (should be like this running 1/1)
```

#### 2. Check Service Status
```bash
kubectl get svc -n ansible | grep fiberneo-ui
# Expected: ClusterIP service on port 80
```

#### 3. Check VirtualService Status
```bash
kubectl get virtualservice -n ansible | grep fiberneo-ui
# Expected: ansible  fiberneo-ui  ["keycloak-gw"]
```

#### 4. Check Health Endpoint
```bash
# Port forward to test locally
kubectl port-forward -n ansible svc/fiberneo-ui 8081:80

# Test health endpoint
curl http://localhost:8081/nginx_status
# Expected: 200 OK response with nginx status

# Test main application
curl http://localhost:8081/
# Expected: HTML content of the FIBERNEO UI
```

#### 5. Check Logs
```bash
# Check if nginx started successfully
kubectl logs -n ansible -l app.kubernetes.io/name=fiberneo-ui --tail=100

# Check for any startup errors or configuration issues
kubectl logs -n ansible -l app.kubernetes.io/name=fiberneo-ui -f
```

#### 6. Check ConfigMap
```bash
kubectl get configmap -n ansible | grep fiberneo-ui
# Expected: ConfigMap with nginx configuration

# View nginx configuration
kubectl get configmap -n ansible fiberneo-ui-cm -o yaml
```

---

## Troubleshooting

### Backend: Common Issues

#### 1. Pod Not Starting
```bash
# Check pod status
kubectl describe pod -n ansible -l app.kubernetes.io/name=fiberneo-service

# Check logs
kubectl logs -n ansible -l app.kubernetes.io/name=fiberneo-service --previous
```

#### 2. Database Connection Issues
```bash
# Verify database credentials in secret
kubectl get secret -n ansible fiberneo -o yaml

# Check database connectivity from pod
kubectl exec -n ansible -it deployment/fiberneo-service -- env | grep -E "(MYSQL|DB_)"
```

#### 3. Service Communication Issues
```bash
# Check if dependent services are running
kubectl get pods -n ansible | grep -E "(base-utility|workflow-management|form-builder)"

# Test service connectivity
kubectl exec -n ansible -it deployment/fiberneo-service -- nslookup base-utility-service
```

#### 4. Secret Access Issues
```bash
# Verify secret provider class
kubectl get secretproviderclass -n ansible

# Check service account binding
kubectl describe serviceaccount -n ansible fiberneo-sa
```

### UI: Common Issues

#### 1. Pod Not Starting
```bash
# Check pod status
kubectl describe pod -n ansible -l app.kubernetes.io/name=fiberneo-ui

# Check logs
kubectl logs -n ansible -l app.kubernetes.io/name=fiberneo-ui --previous
```

#### 2. Nginx Configuration Issues
```bash
# Verify nginx configmap
kubectl get configmap -n ansible fiberneo-ui-cm -o yaml

# Check if nginx.conf is properly mounted
kubectl exec -n ansible -it deployment/fiberneo-ui -- cat /etc/nginx/nginx.conf
```

#### 3. VirtualService Issues
```bash
# Check VirtualService status
kubectl describe virtualservice -n ansible fiberneo-ui

# Verify Istio gateway is running
kubectl get gateway -n ansible
```

#### 4. Service Communication Issues
```bash
# Check if dependent services are running
kubectl get pods -n ansible | grep -E "(keycloak|core-ui-shell|ui-designer)"

# Test service connectivity
kubectl exec -n ansible -it deployment/fiberneo-ui -- nslookup keycloak-service
```

### Log Analysis (Backend & UI)

```bash
# Backend: Application logs
kubectl logs -n ansible -l app.kubernetes.io/name=fiberneo-service -f

# Backend: Sidecar logs
kubectl logs -n ansible -l app.kubernetes.io/name=fiberneo-service -c melody-service -f

# UI: Application logs
kubectl logs -n ansible -l app.kubernetes.io/name=fiberneo-ui -f

# All logs with timestamps (example for backend)
kubectl logs -n ansible -l app.kubernetes.io/name=fiberneo-service --timestamps
```

### Performance Monitoring

```bash
# Check resource usage (backend)
kubectl top pods -n ansible | grep fiberneo

# Check HPA status (backend)
kubectl get hpa -n ansible | grep fiberneo

# Check metrics (backend)
kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods | jq '.items[] | select(.metadata.name | contains("fiberneo"))'

# Check resource usage (ui)
kubectl top pods -n ansible | grep fiberneo-ui

# Check HPA status (ui, if enabled)
kubectl get hpa -n ansible | grep fiberneo-ui

# Check metrics (ui, if exporter enabled)
kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods | jq '.items[] | select(.metadata.name | contains("fiberneo-ui"))'
```

---

## Useful Commands

### Backend

```bash
# Check pod events
kubectl describe pod -n ansible -l app.kubernetes.io/name=fiberneo-service

# Check secret provider status
kubectl get secretproviderclass -n ansible

# Check service account
kubectl get sa -n ansible fiberneo-sa

# Check configmap
kubectl get configmap -n ansible fiberneo-service-conf

# View application properties
kubectl get configmap -n ansible fiberneo-service-conf -o yaml

# Edit configmap and restart
kubectl edit configmap -n ansible fiberneo-service-conf
kubectl rollout restart deployment/fiberneo-service -n ansible
```

### UI

```bash
# Check pod events
kubectl describe pod -n ansible -l app.kubernetes.io/name=fiberneo-ui

# Check VirtualService
kubectl get virtualservice -n ansible fiberneo-ui

# Check configmap
kubectl get configmap -n ansible fiberneo-ui-cm

# View nginx configuration
kubectl get configmap -n ansible fiberneo-ui-cm -o yaml

# Edit configmap and restart
kubectl edit configmap -n ansible fiberneo-ui-cm
kubectl rollout restart deployment/fiberneo-ui -n ansible

# Backup current configuration
kubectl get configmap -n ansible fiberneo-ui-cm -o yaml > fiberneo-ui-config-backup.yaml

# Backup values
helm get values fiberneo-ui -n ansible > fiberneo-ui-values-backup.yaml

# Port forward UI pod
export POD_NAME=$(kubectl get pods --namespace ansible -l "app.kubernetes.io/name=fiberneo-ui,app.kubernetes.io/instance=fiberneo-ui" -o jsonpath="{.items[0].metadata.name}")
echo "Visit http://127.0.0.1:8080 to use your application"
kubectl --namespace ansible port-forward $POD_NAME 8080:80
```

---

## Additional Notes

- The Backend service includes a sidecar container for APM monitoring (melody-service)
- Vault integration is configured for secret injection (Backend)
- The Backend supports horizontal pod autoscaling based on CPU and memory usage
- All database connections are encrypted and use SSL certificates (Backend)
- The UI service uses **Nginx** with **Brotli compression** (optional exporter for metrics)
- **Istio VirtualService** integration for UI routing
- Both services are configured for production with proper resource limits and health checks

**Note:** These deployment guides assume you have the necessary permissions and access to Kubernetes cluster (and Istio for UI), Vault services (for Backend), and required dependencies. Always test in a non-production environment first.

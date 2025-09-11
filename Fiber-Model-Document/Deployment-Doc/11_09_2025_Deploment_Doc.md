# Fiber-Model Platform Deployment Guide

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Service Dependencies](#service-dependencies)
   - [Backend Dependencies](#backend-dependencies)
   - [UI Dependencies](#ui-dependencies)
3. [Backend Deployment](#backend-deployment)
   - [Step 1: Repository Setup](#step-1-repository-setup)
   - [Step 2: Database Setup](#step-2-database-setup)
   - [Step 3: Secret Manager Configuration (Vault)](#step-3-secret-manager-configuration-vault)
   - [Step 4: Configure Secret Provider Service Account](#step-4-configure-secret-provider-service-account)
   - [Step 5: Helm Chart Configuration](#step-5-helm-chart-configuration)
   - [Step 6: Deploy Backend Service](#step-6-deploy-backend-service)
4. [UI Deployment](#ui-deployment)
   - [Step 1: Repository Setup](#ui-step-1-repository-setup)
   - [Step 2: Helm Chart Configuration](#ui-step-2-helm-chart-configuration)
   - [Step 3: Deploy UI Service](#ui-step-3-deploy-ui-service)
5. [Verification](#verification)
   - [Backend Verification](#backend-verification)
   - [UI Verification](#ui-verification)
6. [Troubleshooting](#troubleshooting)
   - [Backend](#backend-troubleshooting)
   - [UI](#ui-troubleshooting)
   - [Monitoring & Performance](#monitoring--performance)
7. [Useful Commands](#useful-commands)
8. [Rollback](#rollback)
9. [Additional Notes](#additional-notes)

---

## Overview
This guide consolidates deployment steps for both the Fiber-Model Backend (Spring Boot service) and the Fiber-Model UI (Nginx-based frontend) using Helm on Kubernetes. It covers prerequisites, dependencies, configuration, deployment, verification, troubleshooting, and rollback.

---

## Prerequisites

Before deploying, ensure the following prerequisites are met:

- ✅ **Kubernetes Cluster** is running and accessible
- ✅ **Helm v3** is installed and configured
- ✅ **Docker Registry** is accessible
- ✅ **Namespace `ansible`** exists
- ✅ Backend: **Vault Secret Manager** is configured; **Crypto.zip** is available
- ✅ UI: **Istio Gateway** is configured (for VirtualService)

---

## Service Dependencies

### Backend Dependencies
- Phase 1: Core Infrastructure (Required First)
  1. **apigw** – API Gateway
  2. **keycloak** – Identity and Access Management
  3. **base-utility** – Core utility services
- Phase 2: Data & Cache Layer (Required Second)
  4. **redis-stack-server** – Caching / session
  5. **onesearch** – Search infrastructure (Global Search)
  6. **cassandra** – Cassandra database

### UI Dependencies
- Phase 1: Core Infrastructure (Required First)
  1. **keycloak** – Identity and Access Management
  2. **core-ui-shell** – UI shell
  3. **ui-designer** – Configuration (e.g., `main.js`)

---

## Backend Deployment

### Step 1: Repository Setup
```bash
# Clone and navigate to backend chart
git clone <your-repo-name>
cd <your-repo-name>
cd fiber-model/Backend

# Verify chart structure
ls            # Chart.yaml  config/  templates/  values.yaml
ls templates/ # configmap.yaml  deployment.yaml  hpa.yaml  service.yaml  serviceaccount.yaml  NOTES.txt  _helpers.tpl
```

### Step 2: Database Setup
```bash
# Optional: Backup existing DB
# mysqldump -u '' -p '' FIBER_MODEL > /path/to/FIBER_MODEL_BACKUP.sql

# 1) Obtain DB SQL from
# https://github.com/visionwaves/visionwaves-deployment/tree/dev/fiber-model/sql
# Download: FIBER_MODEL_WITH_DATA.sql or FIBER_MODEL_WITHOUT_DATA.sql

# 2) Connect to mysql (generated-app-db namespace admin user)
mysql -h <mysql-host> -P 3306 -u <username> -p

# 3) Create DB if needed
CREATE DATABASE IF NOT EXISTS FIBER_MODEL;

# For clean setup:
# DROP DATABASE FIBER_MODEL; CREATE DATABASE FIBER_MODEL;

# 4) Use DB and source dump
USE FIBER_MODEL;
SOURCE /absolute/path/FIBER_MODEL_WITHOUT_DATA.sql;

# Troubleshooting
# - 1049 Unknown database → run: USE FIBER_MODEL;
# - 1064 syntax error → verify SQL file path and content
# - Permissions → ensure admin user
# - Alternative (shell):
#   mysql -u '' -p'' FIBER_MODEL < /absolute/path/FIBER_MODEL_WITHOUT_DATA.sql
```

### Step 3: Secret Manager Configuration (Vault)
1. Port-forward Vault UI (namespace: `vault`) to local 8200 and log in.
2. Create or verify secret `kv/data/fiber-model` with required keys; update values as needed.
3. Prepare crypto environment and encrypt sensitive values.

```bash
# Unzip Crypto bundle
unzip Crypto.zip && cd Crypto/

# Export E_C (decryption key)
export E_C="<your_E_C_value>"

# encodeco.sh usage
# Encrypt: ./encodeco.sh e "VALUE"
# Decrypt: ./encodeco.sh d "ENCODED_VALUE"

# Examples
./encodeco.sh e "jdbc:mysql://<MYSQL_HOST>:3306/FIBER_MODEL?useSSL=true"
./encodeco.sh e "your_db_username"
./encodeco.sh e "your_db_password"
```

Cassandra encrypted keys (example keys expected in Vault):
```bash
commons.cassandra.keyspaceName=<encrypted>
commons.cassandra.localDataCenter=<encrypted>
commons.cassandra.password=<encrypted>
commons.cassandra.username=<encrypted>
commons.cassandra.contactPoints=<encrypted>
commons.cassandra.port=9042
commons.cassandra.request-timeout=5
```

Exported values example (final values stored in Vault):
```bash
export E_C="<encrypted_key>"
export db_pass="<encrypted>"
export db_url="<encrypted>"
export db_user="<encrypted>"
```

Ensure creating the Vault role `fiber-model-role`, ACL policy, and service account `fiber-model-sa` as required.

### Step 4: Configure Secret Provider Service Account
Update chart values and templates to use the service account and inject secrets:
```yaml
# values.yaml
serviceAccount:
  create: false  # true if creating new
  annotations: {}
  name: fiber-model-sa

podAnnotations:
  vault.hashicorp.com/agent-pre-populate-only: 'true'
  prometheus.io/scrape: 'true'
  prometheus.io/path: /fiber-model/actuator/prometheus
  prometheus.io/scheme: http
  prometheus.io/port: '9019'
  vault.hashicorp.com/agent-inject: 'true'
  vault.hashicorp.com/agent-init-first: 'true'
  vault.hashicorp.com/role: fiber-model-role
  vault.hashicorp.com/agent-inject-secret-database-config.txt: kv/data/fiber-model
  vault.hashicorp.com/agent-inject-template-secrets.env: |
    {{- with secret "kv/data/fiber-model" -}}
    {{- range $key, $value := .Data.data -}}
    export {{$key}}="{{$value}}"
    {{- "\n" -}}
    {{- end }}
    {{- end }}
```

Verify `deployment.yaml` uses the service account:
```yaml
spec:
  serviceAccountName: {{ if .Values.serviceAccount.create }}{{ .Values.serviceAccount.name }}{{ else }}fiber-model-sa{{ end }}
```

Apply file changes.

### Step 5: Helm Chart Configuration
Key values overview:
```yaml
replicaCount: 1
image:
  repository: registry.visionwaves.com/<your-fiber-model-image>
  tag: <your-tag>
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
  path: /fiber-model/rest/ping
  initialDelaySeconds: 300
  periodSeconds: 20
  failureThreshold: 3
  timeoutSeconds: 3
readinessProbe:
  path: /fiber-model/rest/ping
  initialDelaySeconds: 60
  periodSeconds: 10
  timeoutSeconds: 3
env:
  servicePort: 8081
  serviceContext: /fiber-model
  PORT: '8081'
  deploymentName: fiber-model-service
```

### Step 6: Deploy Backend Service
```bash
# Verify location
pwd  # /path/to/visionwaves-deployment/fiber-model/Backend

# Inspect chart name and image values
cat Chart.yaml | grep -i name
grep -A 5 "image:" values.yaml

# Deploy/upgrade with image override
helm upgrade <service-name> -n ansible . \
  --install \
  --set image.repository=registry.visionwaves.com/fiber-model \
  --set image.tag=v1_service
```

---

## UI Deployment

### Step 1: Repository Setup
```bash
git clone <your-repo-name>
cd <your-repo-name>
cd fiber-model/ui/fiber-model

# Verify chart structure
ls            # Chart.yaml  configmapfiles/  templates/  values.yaml
ls templates/ # confimap.yaml  deployment.yaml  hpa.yaml  service.yaml  virtualService.yaml  NOTES.txt  _helpers.tpl
ls configmapfiles/ # nginx.conf
```

### Step 2: Helm Chart Configuration
```yaml
replicaCount: 1
image:
  repository: registry.visionwaves.com/fiber-model-ui
  tag: fiber-model-demo-17_v15_ui_demo
  pullPolicy: Always
service:
  type: ClusterIP
  name: fiber-model-ui
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
  context: /fiber-model
  rewriteForSlash: false
gateway:
  enabled: true
  name: ingressgateway
gatewayServers:
  portNumber: 80
  portName: http
  portProtocol: HTTP
  hosts: '"*"'
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

### Step 3: Deploy UI Service
```bash
# Verify location
pwd  # /path/to/visionwaves-deployment/fiber-model/ui/fiber-model

# Inspect chart name and image values
cat Chart.yaml | grep -i name
grep -A 5 "image:" values.yaml

# Deploy/upgrade
helm upgrade fiber-model-ui -n ansible . --install
```

---

## Verification

### Backend Verification
```bash
# Pods
kubectl get pods -n ansible | grep fiber-model
# Services
kubectl get svc -n ansible | grep fiber-model

# Health endpoint
kubectl port-forward -n ansible svc/fiber-model-service 8081:80
curl http://localhost:8081/fiber-model/rest/ping  # Expect 200

# Logs
kubectl logs -n ansible -l app.kubernetes.io/name=fiber-model-service --tail=100
kubectl logs -n ansible -l app.kubernetes.io/name=fiber-model-service --tail=100 | grep "service started successfully"

# HPA
kubectl get hpa -n ansible fiber-model-service
```

### UI Verification
```bash
# Pods
kubectl get pods -n ansible | grep fiber-model-ui
# Services
kubectl get svc -n ansible | grep fiber-model-ui
# VirtualService
kubectl get virtualservice -n ansible | grep fiber-model-ui

# Health and app content
kubectl port-forward -n ansible svc/fiber-model-ui 8081:80
curl http://localhost:8081/nginx_status   # Expect 200
curl http://localhost:8081/               # Expect UI HTML
```

---

## Troubleshooting

### Backend
```bash
# Pod not starting
kubectl describe pod -n ansible -l app.kubernetes.io/name=fiber-model-service
kubectl logs -n ansible -l app.kubernetes.io/name=fiber-model-service --previous

# DB connection issues
kubectl get secret -n ansible fiber-model -o yaml
kubectl exec -n ansible -it deployment/fiber-model-service -- env | grep -E "(MYSQL|DB_)"

# Secret access issues
kubectl get secretproviderclass -n ansible
kubectl describe serviceaccount -n ansible fiber-model-sa
```

### UI
```bash
# Pod not starting
kubectl describe pod -n ansible -l app.kubernetes.io/name=fiber-model-ui
kubectl logs -n ansible -l app.kubernetes.io/name=fiber-model-ui --previous

# Nginx config issues
kubectl get configmap -n ansible fiber-model-ui-cm -o yaml
kubectl exec -n ansible -it deployment/fiber-model-ui -- cat /etc/nginx/nginx.conf

# VirtualService issues
kubectl describe virtualservice -n ansible fiber-model-ui
kubectl get gateway -n ansible
```

### Monitoring & Performance
```bash
# Resource usage
kubectl top pods -n ansible | grep -E "fiber-model|fiber-model-ui"

# HPA
kubectl get hpa -n ansible | grep -E "fiber-model|fiber-model-ui"

# Metrics API
kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods | jq '.items[] | select(.metadata.name | contains("fiber-model"))'
```

---

## Useful Commands
```bash
# Pod events
kubectl describe pod -n ansible -l app.kubernetes.io/name=fiber-model-service
kubectl describe pod -n ansible -l app.kubernetes.io/name=fiber-model-ui

# Secret provider status (Backend)
kubectl get secretproviderclass -n ansible

# Service accounts
kubectl get sa -n ansible fiber-model-sa

# ConfigMaps
kubectl get configmap -n ansible fiber-model-service-conf
kubectl get configmap -n ansible fiber-model-service-conf -o yaml
kubectl get configmap -n ansible fiber-model-ui-cm
kubectl get configmap -n ansible fiber-model-ui-cm -o yaml

# Restart deployments after config changes
kubectl rollout restart deployment/fiber-model-service -n ansible
kubectl rollout restart deployment/fiber-model-ui -n ansible

# Backups
kubectl get configmap -n ansible fiber-model-service-conf -o yaml > fiber-model-config-backup.yaml
helm get values fiber-model-service -n ansible > fiber-model-values-backup.yaml
kubectl get configmap -n ansible fiber-model-ui-cm -o yaml > fiber-model-ui-config-backup.yaml
helm get values fiber-model-ui -n ansible > fiber-model-ui-values-backup.yaml

# Local URL via port-forward (UI)
export POD_NAME=$(kubectl get pods --namespace ansible -l "app.kubernetes.io/name=fiber-model-ui,app.kubernetes.io/instance=fiber-model-ui" -o jsonpath="{.items[0].metadata.name}")
echo "Visit http://127.0.0.1:8080 to use your application"
kubectl --namespace ansible port-forward $POD_NAME 8080:80
```

---

## Rollback
```bash
# List releases
helm list -n ansible

# Backend rollback
helm rollback fiber-model-service -n ansible
# UI rollback
helm rollback fiber-model-ui -n ansible

# Uninstall and reinstall (if needed)
helm uninstall fiber-model-service -n ansible
helm upgrade fiber-model-service -n ansible .

helm uninstall fiber-model-ui -n ansible
helm upgrade fiber-model-ui -n ansible . --install
```

---

## Additional Notes
- The Backend service includes a sidecar for APM monitoring (`melody-service`).
- Vault integration is used for secret injection (Backend).
- Backend exposes Prometheus metrics at `/fiber-model/actuator/prometheus`.
- UI uses Nginx with Brotli; optional nginx-exporter for metrics at `/metrics`.
- UI routes via Istio VirtualService; context is `/fiber-model`.
- Both services support HPA (Backend enabled by default in example; UI disabled by default).
- Database connections are encrypted and use SSL certificates (Backend).
- For production, review and adjust resource requests/limits and health checks.

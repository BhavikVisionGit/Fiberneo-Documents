# Fiber-Model Service Deployment Guide

## Overview
This guide provides step-by-step instructions for deploying the Fiber-Model Service using Helm charts on Kubernetes. The fiber-model service is a Spring Boot application that handles fiber-model-related operations and integrates with various VisionWaves platform services.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Service Dependencies](#service-dependencies)
3. [Deployment Steps](#deployment-steps)
   - [Step 1: Repository Setup](#step-1-repository-setup)
   - [Step 2: Database Setup](#step-2-database-setup)
   - [Step 3: Secret Manager Configuration](#step-3-secret-manager-configuration)
   - [Step 4: Configure Secret Provider Service Account](#step-4-configure-secret-provider-service-account)
   - [Step 5: Helm Chart Configuration](#step-5-helm-chart-configuration)
   - [Step 6: Deploy Service](#step-6-deploy-service)
4. [Service Configuration](#service-configuration)
   - [Dependencies Configuration](#dependencies-configuration)
   - [Templates Overview](#templates-overview)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)
7. [Post-Deployment](#post-deployment)
8. [Additional notes](#additional-notes)

## Prerequisites

Before deploying the fiber-model service, ensure the following prerequisites are met:

- ✅ **Kubernetes Cluster** is running and accessible
- ✅ **Helm** is installed and configured (v3.x)
- ✅ **Docker Registry** is accessible
- ✅ **Vault Secret Manager** is configured
- ✅ **Crypto.zip** is available for decryption
- ✅ **Namespace 'ansible'** is created
- ✅ **Required Dependencies** are deployed (see Service Dependencies section)

## Service Dependencies

The fiber-model service depends on the following services that must be deployed first:

### **Phase 1: Core Infrastructure (Required First)**
1. **apigw** - API Gateway
2. **keycloak** - Identity and Access Management
3. **base-utility** - Core utility services

### **Phase 2: Data & Cache Layer (Required Second)**
4. **redis-stack-server** - Caching and session management
5. **onesearch** - Search engine infrastructure (Global Search)
6. **cassandra** - Cassandra database

## Deployment Steps

### Step 1: Repository Setup

```bash
# Clone the repository (if not already done)
git clone <your-repo-name>
cd <your-repo-name>

# Navigate to fiber-model service directory
cd fiber-model/Backend

# Verify directory structure
ls
# Expected output: Chart.yaml  config/  templates/  values.yaml

# Verify Helm chart structure
ls templates/
# Expected output: configmap.yaml  deployment.yaml  hpa.yaml  service.yaml  serviceaccount.yaml  NOTES.txt  _helpers.tpl
```

### Step 2: Database Setup

```bash
# Backup existing DB (optional)
# mysqldump -u '' -p '' FIBER_MODEL > /path/to/FIBER_MODEL_BACKUP.sql

# 1. Get database dump or source file from the below path
# https://github.com/visionwaves/visionwaves-deployment/tree/dev/fiber-model/sql

# 2. Download FIBER_MODEL_WITH_DATA.sql or FIBER_MODEL_WITHOUT_DATA.sql

# 3. Access mysql cluster in generated-app-db namespace using its admin mysql user
mysql -h <mysql-host> -P 3306 -u <username> -p

# 4. Create a database (if it does not already exist)
CREATE DATABASE IF NOT EXISTS FIBER_MODEL;

# 👉 If database already exists and you want a clean setup:
# DROP DATABASE FIBER_MODEL;
# CREATE DATABASE FIBER_MODEL;

# 5. Use the FIBER_MODEL database and source the downloaded file
USE FIBER_MODEL;
SOURCE /path/to/yourfolder/FIBER_MODEL_WITHOUT_DATA.sql;

# ⚠️ Troubleshooting:
# - If "ERROR 1049 (42000): Unknown database" → run `USE FIBER_MODEL;` first
# - If "ERROR 1064 (42000)" → check the SQL file path (use absolute path)
# - If permissions error → ensure you are logged in as admin user
# - If SOURCE still fails, run from shell instead of MySQL prompt:
#   mysql -u '' -p'' FIBER_MODEL < /path/to/FIBER_MODEL_WITHOUT_DATA.sql
```

### Step 3: Secret Manager Configuration

**Vault Secret Manager Configuration:**

1. Get svc of vault from vault namespace and make port forward to 8200 for accessing the vault UI
2. Login with the username and token from the vault secret manager
3. **Create secret in Vault Secret Manager with name: `fiber-model`** (i.e: kv/data/fiber-model (path of keyvalue of secret manager)) if exists then leave it as it is just check the secret value and update the values

4. **⚠️ Important: Decrypt and update these values before creating the secret:**

**First, setup the crypto environment:**
```bash
# Unzip the Crypto.zip file
unzip Crypto.zip
cd Crypto/

# Export the E_C value from the secrets
export E_C="tso*****sWM=" # Your E_C valid key value
```

**Decrypt and update required values:**

1. **Database Configuration**:
   ```bash
   # encodeco.sh usage
   # Encrypt: ./encodeco.sh e "VALUE_TO_BE_ENCRYPTED"
   # Decrypt: ./encodeco.sh d "ENCODED_VALUE"
   
   # Encrypt MYSQL_URL and IP address
   ./encodeco.sh e "jdbc:mysql://<MYSQL_HOST>:3306/FIBER_MODEL?useSSL=true"
   
   # Encrypt database credentials
   ./encodeco.sh e "your_db_username"
   ./encodeco.sh e "your_db_password"
   ```

2. **Cassandra Configuration**:
   ```bash

   ### ./encodeco.sh e 'This values Decrypt with E_C'

    commons.cassandra.keyspaceName=wCW+20A********fNtHcw==
    commons.cassandra.localDataCenter=kaydO*****PuEOFBmDw==
    commons.cassandra.password=ricl9hm*******2q0KfGgsg==
    commons.cassandra.username=ricl9hm******q0KfGgsg==
    commons.cassandra.contactPoints=LctQlVrPAaNvNh4weC******/GuGX5o0NI34Ut01RVgAV4wX2sllpQBzw==
    commons.cassandra.port=9042
    commons.cassandra.request-timeout=5
   ```

5. **Create the secret with the following values:**

```bash
# This is key used for encryption and decryption
export E_C="tso********sWM="

# Values for DB credentials
export db_pass="o7B1*********bR8Q=="
export db_url="ALhMsWbbR***********ycA=="
export db_user="bIpW***********=="
```

6. **It creates a new secret and its role (fiber-model-role) and ACL policy and check service account (fiber-model-sa) is configured properly**

### Step 4: Configure Secret Provider Service Account

```bash
# 1. Go to the helm chart folder where values.yaml exists
# 2. Update the following values in the values.yaml file:

serviceAccount:
  create: false  # if already created else true
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

# 3. Check the following values in deployment.yaml file as service account name is mentioned in the values.yaml file or default service account is used:
spec:
  serviceAccountName: {{ if .Values.serviceAccount.create }}{{ .Values.serviceAccount.name }}{{ else }}fiber-model-sa{{ end }}

# 4. Apply the above file changes
```

### Step 5: Helm Chart Configuration

The fiber-model service Helm chart includes the following components:

#### **Chart.yaml**
- **Name:** fiber-model-service
- **Version:** 0.1.0
- **Type:** application

#### **values.yaml Key Configuration**

```yaml
# Replica Configuration
replicaCount: 1

# Image Configuration
image:
  repository: registry.visionwaves.com/{Name According to You for Example: fiber-model-demo}
  tag: tag according to you for Example: v1.0.1
  pullPolicy: IfNotPresent

# Service Configuration
service:
  port: 80
  targetPort: 8081
  type: ClusterIP

# Resource Limits
resourcesLimits:
  cpu: 500m
  memory: 2Gi
requestsResources:
  cpu: 500m
  memory: 2Gi

# Autoscaling
autoscaling:
  enabled: true
  minReplicas: 1
  maxReplicas: 3
  targetCPUUtilizationPercentage: 75
  targetMemoryUtilizationPercentage: 75

# Health Checks
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

# Environment Variables
env:
  servicePort: 8081
  serviceContext: /fiber-model
  PORT: '8081'
  deploymentName: fiber-model-service
  # ... other environment variables
  # Update this according to the requirement
```

### Step 6: Deploy Service

```bash
# Verify current directory
pwd
# Should be: /path/to/visionwaves-deployment/fiber-model/Backend

# Get service name from Chart.yaml
cat Chart.yaml
# Look for 'name' field

# Review image configuration in values.yaml
grep -A 5 "image:" values.yaml
# Look for the image section like:
# image:
#   repository: registry.visionwaves.com/fiber-model
#   tag: v1_service
#   pullPolicy: IfNotPresent

# Deploy service using Helm with image override (include tag)
# Note: Change the image repository and tag according to the image pushed in your registry
helm upgrade <service-name> -n ansible . --set image.repository=registry.visionwaves.com/fiber-model --set image.tag=v1_service

# Alternative: Deploy with custom image if needed
# helm upgrade fiber-model-service -n ansible . \
#   --set image.repository=your-registry.com/fiber-model \
#   --set image.tag=your-tag
```

## Service Configuration

### **Dependencies Configuration**

The service connects to:

- **Database**: MariaDB/MySQL (encrypted connection)
- **Redis**: For caching and session management
- **Vault**: For secret management
- **APM**: For application monitoring

#### **Templates Overview**

1. **deployment.yaml** - Main application deployment with sidecar container
2. **service.yaml** - Kubernetes service for internal communication
3. **hpa.yaml** - Horizontal Pod Autoscaler for scaling
4. **configmap.yaml** - Configuration files (application.properties, scripts)
5. **serviceaccount.yaml** - Service account for workload identity
6. **NOTES.txt** - Post-deployment instructions

## Verification

### **1. Check Pod Status**
```bash
kubectl get pods -n ansible | grep fiber-model
# Expected: Running status (should be like this running 3/3 or 4/4 depending on number of replicas)
```

### **2. Check Service Status**
```bash
kubectl get svc -n ansible | grep fiber-model
# Expected: ClusterIP service on port 80
```

### **3. Check Health Endpoint**
```bash
# Port forward to test locally
kubectl port-forward -n ansible svc/fiber-model-service 8081:80

# Test health endpoint
curl http://localhost:8081/fiber-model/rest/ping
# Expected: 200 OK response
```

### **4. Check Logs**
```bash
# Check if service started successfully or not
kubectl logs -n ansible -l app.kubernetes.io/name=fiber-model-service --tail=100 | grep "service started successfully"

kubectl logs -n ansible -l app.kubernetes.io/name=fiber-model-service --tail=100
# Check for any startup errors or connection issues
```

### **5. Check HPA Status**
```bash
kubectl get hpa -n ansible fiber-model-service
# Expected: HPA configured with CPU/Memory targets
# NAME                  REFERENCE                        TARGETS                        MINPODS   MAXPODS   REPLICAS   AGE
# fiber-model-service   Deployment/fiber-model-service   <unknown>/75%, <unknown>/75%   1         3         1          1day
```

## Troubleshooting
 
### **Common Issues**
 
#### 1. Pod Not Starting
```bash
# Check pod status
kubectl describe pod -n ansible -l app.kubernetes.io/name=fiber-model-service
 
# Check logs
kubectl logs -n ansible -l app.kubernetes.io/name=fiber-model-service --previous
```
 
#### 2. Database Connection Issues
```bash
# Verify database credentials in secret
kubectl get secret -n ansible fiber-model -o yaml
 
# Check database connectivity from pod
kubectl exec -n ansible -it deployment/fiber-model-service -- env | grep -E "(MYSQL|DB_)"
```
  
#### 3. Secret Access Issues
```bash
# Verify secret provider class
kubectl get secretproviderclass -n ansible
 
# Check service account binding
kubectl describe serviceaccount -n ansible fiber-model-sa
```
 
### Log Analysis
 
```bash
# Application logs
kubectl logs -n ansible -l app.kubernetes.io/name=fiber-model-service -f
 
# Sidecar logs
kubectl logs -n ansible -l app.kubernetes.io/name=fiber-model-service -c melody-service -f
 
# All logs with timestamps
kubectl logs -n ansible -l app.kubernetes.io/name=fiber-model-service --timestamps
```
 
### Performance Monitoring
 
```bash
# Check resource usage
kubectl top pods -n ansible | grep fiber-model
 
# Check HPA status
kubectl get hpa -n ansible | grep fiber-model
 
# Check metrics
kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods | jq '.items[] | select(.metadata.name | contains("fiber-model"))'
```
 
 
### 2. Configure Monitoring
The service includes Prometheus metrics at `/fiber-model/actuator/prometheus`. Ensure your monitoring system is configured to scrape these metrics.
 
### 3. Backup Configuration
```bash
# Backup current configuration
kubectl get configmap -n ansible fiber-model-service-conf -o yaml > fiber-model-config-backup.yaml
 
# Backup values
helm get values fiber-model-service -n ansible > fiber-model-values-backup.yaml
```
 
### **Useful Commands**
 
```bash
# Check pod events
kubectl describe pod -n ansible -l app.kubernetes.io/name=fiber-model-service
 
# Check secret provider status
kubectl get secretproviderclass -n ansible
 
# Check service account
kubectl get sa -n ansible fiber-model-sa
 
# Check configmap
kubectl get configmap -n ansible fiber-model-service-conf
 
# View application properties
kubectl get configmap -n ansible fiber-model-service-conf -o yaml
 
 
 
#After deployment if need to restart the pods or update the service URLs in the application.properties if needed:
# Edit the configmap and save so that pod will be restarted with the new image if chnaged.
kubectl edit configmap -n ansible fiber-model-service-conf
 
# Restart the deployment to apply changes
kubectl rollout restart deployment/fiber-model-service -n ansible
```
 
### **Rollback Instructions**
 
```bash
# List releases
helm list -n ansible
 
# Rollback to previous version
helm rollback fiber-model-service -n ansible
 
# Or uninstall and reinstall
helm uninstall fiber-model-service -n ansible
helm upgrade fiber-model-service -n ansible .
```
 
---
 
## Additional Notes
 
- The service includes a sidecar container for APM monitoring (melody-service)
- Vault integration is configured for secret injection
- The service supports horizontal pod autoscaling based on CPU and memory usage
- All database connections are encrypted and use SSL certificates
- The service is configured for production use with proper resource limits and health checks
 
For any issues or questions, refer to the application logs and check the dependency services status.
---

**Note:** This deployment guide assumes you have the necessary permissions and access to Vault services, Kubernetes cluster, and the required dependencies. Always test in a non-production environment first.

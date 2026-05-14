#!/bin/bash

set -euo pipefail

# =========================================================
# Variables
# =========================================================
NAMESPACE="monitoring"
RELEASE_NAME="grafana"
STORAGE_CLASS="ebs-gp3"
GRAFANA_PASSWORD="admin123"

echo "🚀 Installing Grafana with Persistent Storage"

# =========================================================
# Add Helm Repo
# =========================================================
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# =========================================================
# Create Namespace
# =========================================================
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# =========================================================
# Cleanup Old Grafana Resources
# =========================================================
# echo "🧹 Cleaning old Grafana resources..."

# kubectl delete deployment ${RELEASE_NAME} -n ${NAMESPACE} --ignore-not-found
# kubectl delete service ${RELEASE_NAME} -n ${NAMESPACE} --ignore-not-found
# kubectl delete serviceaccount ${RELEASE_NAME} -n ${NAMESPACE} --ignore-not-found
# kubectl delete configmap ${RELEASE_NAME} -n ${NAMESPACE} --ignore-not-found
# kubectl delete secret ${RELEASE_NAME} -n ${NAMESPACE} --ignore-not-found

# Optional: Uncomment next line ONLY if you want fresh Grafana storage
# kubectl delete pvc -n ${NAMESPACE} -l app.kubernetes.io/name=grafana

# =========================================================
# Create Stable Admin Secret
# =========================================================
kubectl create secret generic grafana-admin-secret \
  -n ${NAMESPACE} \
  --from-literal=admin-user=admin \
  --from-literal=admin-password=${GRAFANA_PASSWORD} \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Grafana admin secret created"

# =========================================================
# Create Helm Values File
# =========================================================
cat <<EOF > grafana-values.yaml
admin:
  existingSecret: grafana-admin-secret
  userKey: admin-user
  passwordKey: admin-password

service:
  type: ClusterIP

persistence:
  enabled: true
  type: pvc
  storageClassName: ${STORAGE_CLASS}
  accessModes:
    - ReadWriteOnce
  size: 5Gi

datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        url: http://prometheus-server.monitoring.svc.cluster.local
        access: proxy
        isDefault: true
EOF

echo "✅ grafana-values.yaml created"

# =========================================================
# Install Grafana
# =========================================================
helm upgrade --install ${RELEASE_NAME} grafana/grafana \
  -n ${NAMESPACE} \
  -f grafana-values.yaml \
  --version 8.3.8

# =========================================================
# Wait for Deployment
# =========================================================
echo "⏳ Waiting for Grafana rollout..."

kubectl rollout status deployment/${RELEASE_NAME} -n ${NAMESPACE}

# =========================================================
# Verify PVC
# =========================================================
echo ""
echo "📦 PVC Status"
kubectl get pvc -n ${NAMESPACE}

# =========================================================
# Verify Pods
# =========================================================
echo ""
echo "📦 Pod Status"
kubectl get pods -n ${NAMESPACE}

# =========================================================
# Verify Service
# =========================================================
echo ""
echo "🌐 Service Status"
kubectl get svc -n ${NAMESPACE}

echo ""
echo "✅ Grafana installed successfully"
echo ""
echo "🔑 Username: admin"
echo "🔑 Password: ${GRAFANA_PASSWORD}"
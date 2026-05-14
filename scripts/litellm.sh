#!/bin/bash
set -euo pipefail

kubectl create namespace litellm --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic litellm-master-key \
  --from-literal=PROXY_MASTER_KEY="${PROXY_MASTER_KEY:?Error: PROXY_MASTER_KEY env var is not set}" \
  --namespace litellm \
  --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install litellm oci://ghcr.io/berriai/litellm-helm \
  --namespace litellm \
  --create-namespace \
  --wait \
  --set proxy_config.general_settings.master_key="$PROXY_MASTER_KEY" \
  --values - <<'EOF'
replicaCount: 1

image:
  repository: ghcr.io/berriai/litellm-database
  pullPolicy: Always
  tag: ""

service:
  type: ClusterIP
  port: 4000

db:
  useExisting: false
  deployStandalone: true

envVars:
  UI_USERNAME: "admin"
  UI_PASSWORD: "admin123"

proxy_config:
  model_list:
    - model_name: qwen2-5-7b
      litellm_params:
        model: openai/qwen2-5-7b
        api_base: http://vllm-router-service.vllm.svc.cluster.local:80/v1
        api_key: "dummy"
  general_settings:
    master_key: placeholder

resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
  limits:
    cpu: "1"
    memory: "3Gi"
EOF
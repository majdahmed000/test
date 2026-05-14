#!/bin/bash
set -euo pipefail

helm repo add vllm https://vllm-project.github.io/production-stack
helm repo update

helm upgrade --install vllm vllm/vllm-stack \
  --namespace vllm \
  --create-namespace \
  --wait \
  --values - <<'EOF'
servingEngineSpec:
  runtimeClassName: "nvidia"
  imagePullPolicy: "IfNotPresent"
  startupProbe:
    initialDelaySeconds: 15
    periodSeconds: 10
    failureThreshold: 90
  livenessProbe:
    initialDelaySeconds: 15
    periodSeconds: 10
    failureThreshold: 3
  tolerations:
    - key: "nvidia.com/gpu"
      operator: "Exists"
      effect: "NoSchedule"
  modelSpec:
    - name: "qwen2-5-7b"
      repository: "vllm/vllm-openai"
      tag: "latest"
      modelURL: "/data/model"
      replicaCount: 1
      requestGPU: 1
      requestCPU: 4
      requestMemory: "16Gi"
      limitCPU: "8"
      limitMemory: "20Gi"
      pvcStorage: "50Gi"
      storageClass: "ebs-gp3"
      pvcAccessMode:
        - ReadWriteOnce
      initContainer:
        name: "s3-model-loader"
        image: "amazon/aws-cli:latest"
        command:
          - "sh"
          - "-c"
        args:
          - "if [ -f /data/model/config.json ]; then echo 'Model exists, skipping.'; else aws s3 sync s3://llm-k8s-artifacts-eb36c713/models/qwen2.5-7b-instruct/ /data/model/; fi"
        env:
          - name: AWS_DEFAULT_REGION
            value: "us-east-2"
        mountPvcStorage: true
      vllmConfig:
        extraArgs:
          - "--dtype=float16"
          - "--gpu-memory-utilization=0.90"
          - "--max-model-len=8192"
          - "--enable-prefix-caching"
          - "--trust-remote-code"
          - "--served-model-name=qwen2-5-7b"
          - "--enable-auto-tool-choice"
          - "--tool-call-parser=hermes"
routerSpec:
  replicaCount: 1
  routingLogic: "prefixaware"
  engineScrapeInterval: 15
  servicePort: 80
  startupProbe:
    initialDelaySeconds: 15
    periodSeconds: 5
    failureThreshold: 30
EOF
#!/usr/bin/env bash
# Deploys the VICTIM Kubernetes infrastructure (no attack actions here).
# Safe to run during lab setup / provisioning.
set -euo pipefail
NS=attack-demo
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[infra/k8s] applying victim manifests..."
kubectl apply -f "$DIR/k8s/vuln-app.yaml"

echo "[infra/k8s] planting cloud credentials into the app (simulated misconfig)..."
kubectl -n "$NS" create secret generic app-cloud-creds \
  --from-literal=AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-}" \
  --from-literal=AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-}" \
  --from-literal=AWS_DEFAULT_REGION="${AWS_REGION:-us-east-1}" \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart so the pod picks up the secret via envFrom
kubectl -n "$NS" rollout restart deploy/vuln-app

echo "[infra/k8s] deploying attacker C2 pod..."
kubectl apply -f "$DIR/k8s/attacker.yaml"

echo "[infra/k8s] waiting for workloads..."
kubectl -n "$NS" rollout status deploy/vuln-app --timeout=180s
kubectl -n "$NS" wait --for=condition=Ready pod/attacker --timeout=180s

echo "[infra/k8s] done. Victim app + attacker box are up in ns/$NS."
kubectl -n "$NS" get pods -o wide

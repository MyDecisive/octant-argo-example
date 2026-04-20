#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

# --- Configuration ---
NAMESPACE="argocd"
ACCOUNT="apiUser"
# ---------------------

echo "⚙️  Step 1: Patching argocd-cm to add API account '$ACCOUNT'..."
kubectl patch configmap/argocd-cm -n "$NAMESPACE" \
  --type merge \
  -p "{\"data\":{\"accounts.$ACCOUNT\":\"apiKey\"}}"

echo "⚙️  Step 2: Patching argocd-rbac-cm to grant 'role:admin' to '$ACCOUNT'..."
kubectl patch configmap/argocd-rbac-cm -n "$NAMESPACE" \
  --type merge \
  -p "{\"data\":{\"policy.csv\":\"g, $ACCOUNT, role:admin\n\"}}"

echo "🔐 Step 3: Retrieving initial admin password..."
# Note: If the initial secret was deleted, you must replace the command below with: ADMIN_PASSWORD="YourPassword"
ADMIN_PASSWORD=$(kubectl -n "$NAMESPACE" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "")

if [ -z "$ADMIN_PASSWORD" ]; then
    echo "⚠️  WARNING: Could not extract password. Please hardcode it in the script."
    # Temporarily hardcode it here for the script to continue if you already changed it
    ADMIN_PASSWORD="YOUR_ACTUAL_PASSWORD" 
fi

echo "🔑 Step 4: Logging into ArgoCD CLI (Bypassing Tilt via native port-forward)..."
set +e
# We replace the SERVER IP with the built-in port-forwarding flags.
# The CLI connects to a random argocd-server port using its own tunnel.
LOGIN_OUTPUT=$(argocd login "argocd-server" \
  --port-forward --port-forward-namespace "$NAMESPACE" \
  --plaintext \
  --username admin \
  --password "$ADMIN_PASSWORD" 2>&1)
LOGIN_EXIT_CODE=$?
set -e

# Catch the error and print a helpful message
if [ $LOGIN_EXIT_CODE -ne 0 ]; then
    echo ""
    echo "❌ CONNECTION FAILED: Could not log into ArgoCD."
    echo "=================================================="
    echo "Diagnostic Output from ArgoCD CLI:"
    echo "$LOGIN_OUTPUT"
    echo "=================================================="
    exit 1
fi

echo "🎫 Step 5: Generating API token for '$ACCOUNT' (expires in 90 days)..."
API_TOKEN=$(argocd account generate-token \
  --account "$ACCOUNT" \
  --port-forward --port-forward-namespace "$NAMESPACE" \
  --plaintext \
  --expires-in 2160h)

echo ""
echo "=================================================="
echo "✅ Setup Complete!"
echo "=================================================="
echo "🌐 K8s Hostname:    http://argocd-server.$NAMESPACE.svc.cluster.local"
echo "👤 Admin Password:  $ADMIN_PASSWORD"
echo "🪙  API Token:      $API_TOKEN"
echo "=================================================="
echo "ℹ️  Your local CLI is authenticated. Note: Future shell commands will also require the --port-forward flag unless you log in via Tilt directly."
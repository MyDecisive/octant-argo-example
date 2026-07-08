# Justfile for installing and running the Octant app locally with Kind + Argo CD.
#
# Usage:
#   just --list
#   just bootstrap-octant
#   just deploy-octant
#   just local-setup

set shell := ["bash", "-euo", "pipefail", "-c"]
set quiet

cluster := "octant-sandbox"
kind_config := "kind-config.yaml"

argocd_namespace := "argocd"
argocd_release := "argo-cd"
argocd_helm_repo := "https://argoproj.github.io/argo-helm"
argocd_chart := "argo-cd"
argocd_chart_version := "9.1.5"
# Host ports must match kind-config.yaml extraPortMappings.
argocd_port := "1443"
argocd_node_port := "31443"
argocd_host := "localhost:" + argocd_port
argocd_account := "apiUser"
argocd_token_ttl := "2160h"

octant_namespace := "octant"
octant_port := "5678"
octant_node_port := "30678"

# Show available commands
default:
    just --list

# Install local prerequisites
prereqs:
    brew bundle --file=./Brewfile

# Verify local prerequisites
verify-prereqs:
    for cmd in docker kind kubectl helm argocd; do \
        if command -v "$cmd" >/dev/null; then \
            printf "✓ %-10s %s\n" "$cmd" "$(command -v "$cmd")"; \
        else \
            echo "✗ $cmd (missing)" >&2; \
            exit 1; \
        fi; \
    done; \
    if ! docker info >/dev/null 2>&1; then \
        echo "✗ docker daemon is not running. Start Docker Desktop and retry." >&2; \
        exit 1; \
    fi

# Create the local Kind cluster
create-cluster:
    if kind get clusters | grep -qx {{cluster}}; then \
      node="{{cluster}}-control-plane"; \
      argocd_mapping="$(docker port "$node" {{argocd_node_port}}/tcp 2>/dev/null || true)"; \
      octant_mapping="$(docker port "$node" {{octant_node_port}}/tcp 2>/dev/null || true)"; \
      if printf "%s\n" "$argocd_mapping" | grep -Eq '(^|:){{argocd_port}}$' && printf "%s\n" "$octant_mapping" | grep -Eq '(^|:){{octant_port}}$'; then \
        echo "Kind cluster {{cluster}} already exists with expected host port mappings."; \
      else \
        echo "Kind cluster {{cluster}} already exists without expected host port mappings from {{kind_config}}." >&2; \
        echo "Run 'just cleanup' and then 'just bootstrap-octant' to recreate it." >&2; \
        exit 1; \
      fi; \
    else \
      kind create cluster --config {{kind_config}}; \
    fi

# Delete the local Kind cluster
delete-cluster:
    kind delete cluster --name {{cluster}}

# Install or upgrade Argo CD in the local cluster
install-argocd:
    helm upgrade --install {{argocd_release}} {{argocd_chart}} \
      --repo {{argocd_helm_repo}} \
      --version {{argocd_chart_version}} \
      --namespace {{argocd_namespace}} \
      --create-namespace \
      --set server.service.type=NodePort \
      --set server.service.nodePortHttps={{argocd_node_port}} \
      --wait \
      --timeout 5m

# Wait until Argo CD can serve, render, and reconcile applications
wait-argocd:
    kubectl -n {{argocd_namespace}} rollout status deployment/{{argocd_release}}-argocd-server --timeout=120s
    kubectl -n {{argocd_namespace}} rollout status deployment/{{argocd_release}}-argocd-repo-server --timeout=120s
    kubectl -n {{argocd_namespace}} rollout status statefulset/{{argocd_release}}-argocd-application-controller --timeout=120s

# Patch the Argo CD config map from the repo
patch-argocd-cm:
    kubectl patch cm/argocd-cm \
      --type=merge \
      -n {{argocd_namespace}} \
      --patch-file argocd/argocd-cm.yaml

# Apply the app-of-apps manifest for Octant
deploy-octant:
    kubectl apply -f argocd/argocd.yaml

# Wait until the Octant service exists
[private]
wait-octant-service:
    kubectl wait --for=create namespace/{{octant_namespace}} --timeout=5m >/dev/null
    kubectl -n {{octant_namespace}} wait --for=create svc/octant --timeout=5m >/dev/null

# Expose Argo CD and Octant through Kind host ports
patch-nodeports: wait-octant-service
    kubectl -n {{argocd_namespace}} patch svc/{{argocd_release}}-argocd-server \
      --type=strategic \
      -p '{"spec":{"type":"NodePort","ports":[{"name":"https","port":443,"nodePort":{{argocd_node_port}}}]}}' >/dev/null
    kubectl -n {{octant_namespace}} patch svc/octant \
      --type=strategic \
      -p '{"spec":{"type":"NodePort","ports":[{"port":5678,"nodePort":{{octant_node_port}}}]}}' >/dev/null

# Full cluster + Argo CD setup
setup: verify-prereqs create-cluster install-argocd wait-argocd patch-argocd-cm

# Full bootstrap including Octant app deployment
bootstrap-octant: setup deploy-octant patch-nodeports

# Backward-compatible alias for the old command name
[private]
octant-bootstrap: bootstrap-octant

# Show the local Argo CD UI URL
port-forward-argocd:
    echo "Argo CD is available at https://{{argocd_host}} via the Kind host port."

# Show the local Octant UI URL
port-forward-octant:
    echo "Octant is available at http://localhost:{{octant_port}} via the Kind host port."

# Show Octant pods
octant-status:
    kubectl -n {{octant_namespace}} get pods,svc

# Show Argo CD applications
argocd-apps:
    kubectl -n {{argocd_namespace}} get applications

# Delete the local Kind cluster
cleanup: delete-cluster

# Configure the ArgoCD API user
configure-argocd-api-user:
    kubectl patch configmap/argocd-cm -n {{argocd_namespace}} \
      --type merge \
      -p '{"data":{"accounts.{{argocd_account}}":"apiKey"}}' >/dev/null
    kubectl patch configmap/argocd-rbac-cm -n {{argocd_namespace}} \
      --type merge \
      -p '{"data":{"policy.csv":"g, {{argocd_account}}, role:admin\n"}}' >/dev/null

# Get the ArgoCD admin password
argocd-admin-password:
    kubectl -n {{argocd_namespace}} get secret argocd-initial-admin-secret \
      -o jsonpath="{.data.password}" | base64 -d

# Login to ArgoCD as admin
argocd-login password="": configure-argocd-api-user
    password='{{password}}'; \
    if [ -z "$password" ]; then \
      password="$(just argocd-admin-password)"; \
    fi; \
    output="$(argocd login "{{argocd_host}}" \
      --username admin \
      --insecure \
      --password "$password" 2>&1)" || { \
        printf "%s\n" "$output" >&2; \
        exit 1; \
      }

# Wait until Argo CD has reloaded the API user configuration
[private]
wait-argocd-api-user:
    for i in $(seq 1 30); do \
      if argocd account get --account {{argocd_account}} >/dev/null 2>&1; then \
        exit 0; \
      fi; \
      sleep 2; \
    done; \
    echo "Timed out waiting for Argo CD account {{argocd_account}} to become available." >&2; \
    exit 1

# Generate an ArgoCD API token
[private]
generate-argocd-api-token: wait-argocd-api-user
    argocd account generate-token \
      --account {{argocd_account}} \
      --expires-in {{argocd_token_ttl}}

# Get an ArgoCD API token
argocd-api-token: argocd-login generate-argocd-api-token

# Get local ArgoCD hostname and API token
local-setup:
    admin_password="$(just argocd-admin-password)" ; \
    just argocd-login "$admin_password" ; \
    api_token="$(just generate-argocd-api-token)" ; \
    echo "🌐 K8s Hostname  : {{argocd_release}}-argocd-server.{{argocd_namespace}}.svc.cluster.local" ; \
    echo "👤 Admin Password: $admin_password" ; \
    echo "🪙 API Token     : $api_token"

# Justfile for installing and running the Octant app locally with Kind + Argo CD.
#
# Usage:
#   just --list
#   just bootstrap
#   just deploy-octant
#   just port-forward-argocd
#   just port-forward-octant

set shell := ["bash", "-cu"]

cluster := "octant-sandbox"
argocd_namespace := "argocd"
octant_namespace := "octant"
argocd_release := "argo-cd"
argocd_chart_version := "9.1.5"
argocd_port := "1443"
octant_port := "5678"

# Show available commands
default:
    just --list

# Install local prerequisites
prereqs:
    brew install argocd

# Create the local Kind cluster
create-cluster:
    kind create cluster --name {{cluster}}

delete-cluster:
    kind delete cluster --name {{cluster}}

# Add/update the Argo Helm repo
helm-repos:
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update

# Install or upgrade Argo CD in the local cluster
install-argocd: helm-repos
    helm upgrade --install {{argocd_release}} argo/argo-cd \
      --version {{argocd_chart_version}} \
      --namespace {{argocd_namespace}} \
      --create-namespace

# Wait until Argo CD server is ready
wait-argocd:
    kubectl -n {{argocd_namespace}} rollout status deployment {{argocd_release}}-argocd-server

# Patch the Argo CD config map from the repo
patch-argocd-cm:
    kubectl patch cm/argocd-cm \
      --type=merge \
      -n {{argocd_namespace}} \
      --patch-file argocd/argocd-cm.yaml

# Apply the app-of-apps manifest for Octant
deploy-octant:
    kubectl apply -f argocd/argocd.yaml

# Full cluster + Argo CD setup
setup: create-cluster install-argocd wait-argocd patch-argocd-cm

# Full bootstrap including Octant app deployment
octant-bootstrap: setup deploy-octant

# Port-forward Argo CD UI to https://localhost:1443
port-forward-argocd:
    kubectl -n {{argocd_namespace}} port-forward svc/{{argocd_release}}-argocd-server {{argocd_port}}:443

# Port-forward Octant UI to http://localhost:5678
port-forward-octant:
    kubectl -n {{octant_namespace}} port-forward svc/octant {{octant_port}}:5678

# Run the local Argo CD helper script
local-setup:
    ./argo-cd-local-setup.sh

# Show Octant pods
octant-status:
    kubectl -n {{octant_namespace}} get pods,svc

# Show Argo CD applications
argocd-apps:
    kubectl -n {{argocd_namespace}} get applications

# Delete the local Kind cluster
cleanup:
    kind delete cluster --name {{cluster}}

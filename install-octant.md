# Installing Octant App

## Prerequisites

```bash
brew install argocd
```

## Use this repo/branch

[https://github.com/MyDecisive/octant-argo-example/tree/feat/octant-app](https://github.com/MyDecisive/octant-argo-example/tree/feat/octant-app)

## Create a cluster

```bash
kind create cluster --name octant-sandbox
```

## Spin up Argo CD in the Cluster

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm upgrade --install argo-cd argo/argo-cd \
  --version 9.1.5 \
  --namespace argocd \
  --create-namespace
```


## Ensure Argo CD is deployed and ready to use

```bash
kubectl -n argocd rollout status deployment argo-cd-argocd-server
```

## Apply argo cd config map to cluster in argocd namespace

```bash
kubectl patch cm/argocd-cm \
  --type=merge \
  -n argocd \
  --patch-file argocd/argocd-cm.yaml
```

## Apply app of apps manifest for octant

```bash
kubectl apply -f argocd/argocd.yaml
```

## Optional: Port-forward the argocd server to watch application state, open argo cd ui at localhost:1443

```bash
kubectl -n argocd port-forward svc/argo-cd-argocd-server 1443:443
```

Port-forward the octant app to start running the ui

```bash
kubectl -n octant port-forward svc/octant 5678:5678
```

## Open octant ui at
[http://localhost:5678/](http://localhost:5678/)

Get to Connect to your Kubernetes Cluster screen and run `./argo-cd-local-setup.sh` to get your argo cd relevant information.. input the data and click next.


my inputs were
connection-name: test-dd
argo cd cluster url: https://argocd-server.argocd.svc.cluster.local
Argo api token: *****

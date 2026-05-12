# 🚧 WORK IN PROGRESS - COME BACK SOON 🚧

# octant-argo-example

This repo is an example of how to use and run Octant (by MyDecisive) in an Argo CD App of Apps setup.

## Prereqs

* [Tilt](https://docs.tilt.dev/install.html)

On Mac OS you can install Tilt with Homebrew:

```bash
brew install tilt
```

## Deployment method

If you have a cluster with Argo CD installed use [these instructions]().

If you need a cluster for sandbox-like testing, use [these instructions](#sandbox-setup).

## Sandbox setup

Start Docker.

> [WARN]
> Use this repo for sandbox testing only.

Create a Cluster

```bash
kind create cluster --name octant-sandbox
```

## Octant Installation Options

1. [Tilt](#option-1-tilt)
1. [Kubernetes API](#option-2-kubernetes-api)

### Option 1. Tilt

Apply tilt file via the following command

```bash
tilt up
```

### Option 2. Kubernetes API

Install Argo CD via Helm:

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm upgrade --install argo-cd argo/argo-cd \
  --version 9.1.5 \
  --namespace argocd \
  --create-namespace
```

Wait for Argo CD server

```bash
kubectl -n argocd rollout status deployment argo-cd-argocd-server
```

```bash
# Patch argocd-cm
kubectl patch cm/argocd-cm \
  --type=merge \
  -n argocd \
  --patch-file argocd/argocd-cm.yaml

# Apply the Argo CD app-of-apps manifest:
kubectl apply -f argocd/argocd.yaml

# Port-forward equivalent of k8s_resource('argocd-server', port_forwards=1443):
kubectl -n argocd port-forward svc/argo-cd-argocd-server 1443:443
```


## View Application Health with Argo CD UI

Port-forward argo cd server with this command or k9s.

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

Open [Argo CD UI](http://localhost:8080)

Use the following credentials

username: `admin`

Get password from the following:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

It will take a while for the argo cd apps to sync and for the mdai helm chart to install an MdaiHub and the Octant ui. Once these are up and running you can start using Octant.

You don't need to use Argo CD for the most part, but you can utilize their UI to ensure your Apps are healthy and creating correctly.

## Using Octant

Port forward to 8081

```
kubectl -n octant port-forward svc/octant-ui 8081:8080
```

Open the app at [http://localhost:8081/](http://localhost:8081/), begin connecting your DD agent.


### How to get Argo CD information

We've included a script to access Argo CD related fields. Run the command from your terminal to get access to the following Argo fields `K8s Hostname`, `Admin Password`, and `API Token`

```
./argo-cd-local-setup.sh
```

These will be used in the connect flow.

### How to get Datadog information

>[!INFO]
>Make sure the namespace is the same namespace your collector is in.
>
>Alternatively, you can create a secret per namespace where resources require the secret.

The following creates a secret in `your_namespace` (please replace with where the collector is installed, probably `mdai`)

```
kubectl -n your_namespace create secret generic datadog-secret --from-literal api-key=*****dd_api_key*****
```

## Connect your Datadog agent

You will need to create or use existing agent

### New Datadog agent

```
helm repo add datadog https://helm.datadoghq.com
helm repo update
helm install datadog-agent -f connections/datadog/dd_values.yaml datadog/datadog --create-namespace -n datadog
kubectl -n datadog create secret generic datadog-secret --from-literal api-key=*****dd_api_key*****
```

### Existing Datadog agent

If you already have a Datadog agent installed in the cluster, you will need to update the config using the Octant guide in Step 5 of the install + connect flow.

## Utilize mock data

The mock-data manifests create synthetic logs and traces in the `synthetics` namespace. Apply these after the MDAI chart has created the collectors in the `mdai` namespace.

```bash
kubectl create namespace synthetics
kubectl apply -f mock-data/
```

Verify the generators are running:

```bash
kubectl -n synthetics get deploy,cronjob,pod
```

Remove the mock-data generators:

```bash
kubectl delete -f mock-data/traces.yaml
kubectl delete -f mock-data/logs.yaml
kubectl delete namespace synthetics
```



## Make sure you update your sampling policy so data sends through

Run the following curls to ensure you send data

For log sampling

```bash
curl --location 'http://localhost:8081/variables/hub/test-dd/var/logs_ratio_number' \
--header 'Content-Type: application/json' \
--data '{"data": "50"}'
```

For trace sampling
```bash
curl --location 'http://localhost:8081/variables/hub/test-dd/var/traces_ratio_number' \
--header 'Content-Type: application/json' \
--data '{"data": "50"}'
```

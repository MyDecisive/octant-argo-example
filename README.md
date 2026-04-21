# 🚧 THIS REPO IS UNDER CONSTRUCTION. PLEASE COME BACK SOON 🚧

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

Apply tilt file via the following command

```bash
tilt up
```

Port-forward argo cd server with this command or k9s.

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:8080
```

Open [Argo CD UI](http://localhost:8080)

Use the following credentials

username: `admin`

Get password from the following:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

It will take a while for the argo cd apps to sync and for the mdai helm chart to install an MdaiHub and the Octant ui. Once these are up and running you can start using Octant.

## Using Octant

Port forward to 8081

Open the app at [http://localhost:8081/](http://localhost:8081/), begin connecting your DD agent.


### How to get Argo CD information

We've included a script to access Argo CD related fields. Run the command from your terminal to get access to the following Argo fields `K8s Hostname`, `Admin Password`, and `API Token`

```
./argo-cd-local-setup.sh
```

These will be used in the connect flow.

### How to get Datadog information

todo

create or use existing agent

change config

etc

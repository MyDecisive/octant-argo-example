# Installing the Octant App Locally

These instructions use [`just`](https://github.com/casey/just) to run the setup commands for a local Kind cluster, Argo CD, and the Octant app.

## Prerequisites

Install `just` if you do not already have it:

```bash
brew install just
```

Install the Argo CD CLI:

```bash
just prereqs
```

You also need these tools available locally:

```bash
brew install kind kubectl helm
```

## Repository and Branch

Use this repo and branch:

```bash
git clone https://github.com/MyDecisive/octant-argo-example.git
cd octant-argo-example
git checkout feat/octant-app
```

Copy the `Justfile` into the root of the repository if it is not already there.

## See Available Commands

```bash
just --list
```

## Full Setup

Run the full bootstrap command:

```bash
just octant-bootstrap
```

This will:

1. Create a Kind cluster named `octant-sandbox`.
2. Add and update the Argo Helm repo.
3. Install Argo CD chart version `9.1.5`.
4. Wait for the Argo CD server, repo-server, and application-controller to become ready.
5. Patch the Argo CD config map from `argocd/argocd-cm.yaml`.
6. Apply the `octant-bootstrap` app-of-apps manifest from `argocd/argocd.yaml`.

## Manual Step-by-Step Setup

If you prefer to run one step at a time:

```bash
just create-cluster
just install-argocd
just wait-argocd
just patch-argocd-cm
just deploy-octant
```

## Open the Argo CD UI

In one terminal, run:

```bash
just port-forward-argocd
```

Then open:

```text
https://localhost:1443
```

## Open the Octant UI

In another terminal, run:

```bash
just port-forward-octant
```

Then open:

```text
http://localhost:5678/
```

## Connect Octant to Argo CD

When you reach the **Connect to your Kubernetes Cluster** screen in the Octant UI, run:

```bash
just local-setup
```

Use the values from the script output.

Example values:

```text
connection-name: test-dd
argo cd cluster url: https://argocd-server.argocd.svc.cluster.local
Argo api token: <token from local setup script>
```

Then click **Next**.

## Useful Commands

Check Octant resources:

```bash
just octant-status
```

Check Argo CD applications:

```bash
just argocd-apps
```

## Cleanup

Delete the local Kind cluster:

```bash
just cleanup
```

## Troubleshooting

### Argo CD server is not ready

Run:

```bash
just wait-argocd
```

### Octant service does not exist yet

Check whether the app has been created by Argo CD:

```bash
just argocd-apps
```

You should see both `octant-bootstrap` and the child `octant` Application while Argo CD is managing the install.

Then check the Octant namespace:

```bash
just octant-status
```

### Port is already in use

Change the port variables at the top of the `Justfile`:

```just
argocd_port := "1443"
octant_port := "5678"
```

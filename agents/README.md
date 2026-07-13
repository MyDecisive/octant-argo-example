# Agent Context

This repo is a sandbox example for running Octant by MyDecisive with Argo CD App of Apps in a local Kind cluster.

## Documentation Ownership

- Keep `README.md` short. It should point readers to the detailed docs instead of duplicating full install or testing steps.
- `docs/installation.md` owns the local sandbox install flow for this repo.
- `docs/testing.md` owns post-install validation, monitoring, mock data, and troubleshooting.
- The upstream Octant repo also has an install guide at `https://github.com/MyDecisive/octant/blob/main/docs/installation.md` that points to this canonical guide and link to it from the other repo.

## Install Flow

The `Justfile` is the source of truth for local install commands. Verify docs against `just --list` and `just --dry-run octant-bootstrap` when changing install instructions.

Current local flow:

```bash
just prereqs
just octant-bootstrap
just port-forward-octant
just local-setup
```

Useful status checks:

```bash
just argocd-apps
just octant-status
just wait-argocd
```

## Argo CD and Octant Details

- Default Kind cluster name: `octant-sandbox` (bootstrap accepts an optional custom name)
- Argo CD namespace: `argocd`
- Octant namespace: `octant`
- Argo CD service: `argo-cd-argocd-server`
- Octant service: `octant`
- Argo CD local URL: `https://localhost:1443`
- Octant local URL: `http://localhost:5678`

The Argo CD UI uses a self-signed cert through the local port-forward. Chrome shows a privacy warning; users need to choose **Advanced** and then **Proceed to localhost (unsafe)**.

`just local-setup` mutates Argo CD config/RBAC for the `apiUser` account and generates an API token. Do not commit generated tokens or passwords.

## Chart Versioning

`argocd/apps/octant.yaml` tracks the Octant Helm chart from `ghcr.io/mydecisive/charts`.

Use a lower-bound semver constraint, such as `targetRevision: ">=0.1.72"`, to track newer chart releases while preventing older chart selection. Do not use `targetRevision: "*"` for this chart: Argo CD resolved it to `0.1.11` even though Helm CLI resolved `--version '*'` to `0.1.72`. Helm also rejects `latest` as an improper version constraint for this chart.

The validator version is currently pinned separately under:

```yaml
validator:
  version: 0.1.7
```

Do not change the validator pin unless the task explicitly includes validator upgrades.

## Testing Notes

When a live `octant-sandbox` cluster already exists, do not recreate it just to test docs. Prefer:

```bash
kind get clusters
kubectl config current-context
just argocd-apps
just octant-status
```

Port-forward smoke checks that have been useful:

```bash
just port-forward-octant
curl -I http://localhost:5678
```

```bash
just port-forward-argocd
curl -k -I https://localhost:1443
```

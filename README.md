# octant-argo-example

This repo is an example of how to run Octant by MyDecisive in a local Argo CD App of Apps setup.

Use it for sandbox testing only.

## Documentation

- [Install Octant locally](docs/installation.md)
- [Test and troubleshoot the local install](docs/testing.md)

## Prerequisites

1. [Docker](https://www.docker.com/products/docker-desktop/)
1. [Kubernetes](https://kubernetes.io/releases/download/)
1. [`kubectl` and `kind`](https://kubernetes.io/docs/tasks/tools/)
1. [Helm](https://helm.sh/docs/intro/install/)
1. [`just`](https://just.systems/man/en/installation.html)
1. [Argo CD CLI](https://argo-cd.readthedocs.io/en/stable/getting_started/#2-download-argo-cd-cli)
1. [`k9s`](https://k9scli.io/topics/install/) (optional)

## Quick Start

Start Docker, then install and deploy the local sandbox:

```bash
just octant-bootstrap
```

To use a different Kind cluster name, pass it to the bootstrap command:

```bash
just octant-bootstrap my-cluster
```

If the requested Kind cluster already exists, bootstrap reuses it after checking
that its `kind-my-cluster` Kubernetes context is available.

Port-forward the Octant service to access it in your browser:

```bash
just port-forward-octant
```

Access Octant at:

[http://localhost:5678](http://localhost:5678)


For a more detailed install, follow the full [installation guide](docs/installation.md).

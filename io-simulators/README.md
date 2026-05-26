```sh
argocd app create io-simulators \
  --repo https://github.com/MyDecisive/octant-argo-example.git \
  --revision rlaw/octant-wip \
  --path io-simulators \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace mdai \
  --helm-set connection_name=argonis \
  --sync-policy automated \
  --auto-prune \
  --port-forward \
  --port-forward-namespace="argocd" \
  --plaintext
```

```sh
argocd app sync io-simulators \
  --plaintext \
  --port-forward \
  --port-forward-namespace="argocd"
```
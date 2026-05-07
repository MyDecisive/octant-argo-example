load('ext://helm_remote', 'helm_remote')

allow_k8s_contexts([
    'octant-sandbox',
    'kind'
])

# ArgoCD
helm_remote('argo-cd',
  repo_url='https://argoproj.github.io/argo-helm',
  version='9.1.5',
  namespace='argocd',
  create_namespace=True,
)
k8s_resource('argo-cd-argocd-server', port_forwards=1443)

local_resource(
  'patch-argocd-cm',
  'kubectl patch cm/argocd-cm --type=merge -n argocd --patch-file argocd/argocd-cm.yaml',
  deps=['argocd/argocd-cm.yaml'],
  resource_deps = ['argo-cd-argocd-server'])

k8s_yaml("argocd/argocd.yaml")

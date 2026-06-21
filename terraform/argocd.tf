provider "helm" {
  kubernetes {
    config_path = "./kubeconfig.yaml"
    insecure = true
  }
}

resource "helm_release" "argocd" {
  depends_on = [null_resource.install_workers, null_resource.get_credentials]
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "6.7.1"

  set {
    name  = "server.service.type"
    value = "NodePort"
  }

  # NodePorts fixos e DIFERENTES dos usados pelo Traefik (30080/30443),
  # para não haver colisão de tráfego entre app e ArgoCD.
  set {
    name  = "server.service.nodePortHttp"
    value = "30880"
  }

  set {
    name  = "server.service.nodePortHttps"
    value = "30943"
  }
}
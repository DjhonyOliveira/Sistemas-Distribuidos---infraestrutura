resource "kubernetes_manifest" "argocd_application" {
  depends_on = [helm_release.argocd]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "my-app-stack"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      
      source = {
        repoURL        = "https://github.com/DjhonyOliveira/Sistemas-Distribuidos---infraestrutura.git"
        targetRevision = "HEAD"
        path           = "argocd-apps"
      }
      
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }
      
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }
}
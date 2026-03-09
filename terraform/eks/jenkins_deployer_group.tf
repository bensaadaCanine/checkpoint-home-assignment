provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name
    ]
  }
}

resource "kubernetes_namespace_v1" "microservices" {
  metadata {
    name = "microservices"
  }
}

resource "kubernetes_role_v1" "jenkins_deployer" {
  metadata {
    name      = "helm-deployer"
    namespace = kubernetes_namespace_v1.microservices.metadata[0].name
  }

  rule {
    api_groups = ["", "apps", "extensions"]

    resources = [
      "deployments",
      "services",
      "pods",
      "configmaps",
      "secrets"
    ]

    verbs = [
      "get",
      "list",
      "watch",
      "create",
      "update",
      "patch",
      "delete"
    ]
  }
}

resource "kubernetes_role_binding_v1" "jenkins_deploy" {
  metadata {
    name      = "jenkins-deploy"
    namespace = kubernetes_namespace_v1.microservices.metadata[0].name
  }

  subject {
    kind      = "Group"
    name      = "jenkins-deployers"
    api_group = "rbac.authorization.k8s.io"
  }

  role_ref {
    kind      = "Role"
    name      = kubernetes_role_v1.jenkins_deployer.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

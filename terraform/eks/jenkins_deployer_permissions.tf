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

resource "kubernetes_namespace_v1" "jenkins-agents" {
  metadata {
    name = "jenkins-agents"
  }
}

resource "kubernetes_cluster_role_v1" "jenkins" {
  metadata {
    name = "jenkins-deployer"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "pods/exec", "services"]
    verbs      = ["create", "get", "list", "watch", "delete", "update", "patch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets", "replicasets"]
    verbs      = ["create", "get", "list", "watch", "delete", "update", "patch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["create", "get", "list", "watch", "delete", "update", "patch"]
  }
}

resource "kubernetes_role_binding_v1" "jenkins_microservices" {
  metadata {
    name      = "jenkins-deployer-binding"
    namespace = "microservices"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.jenkins.metadata[0].name
  }

  subject {
    kind      = "User"
    name      = "jenkins"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_role_binding_v1" "jenkins_agents" {
  metadata {
    name      = "jenkins-deployer-binding"
    namespace = "jenkins-agents"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.jenkins.metadata[0].name
  }

  subject {
    kind      = "User"
    name      = "jenkins"
    api_group = "rbac.authorization.k8s.io"
  }
}

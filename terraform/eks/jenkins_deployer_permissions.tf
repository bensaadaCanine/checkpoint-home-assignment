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

resource "aws_security_group_rule" "jenkins_to_eks" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = data.terraform_remote_state.jenkins.outputs.jenkins_agent_sg.id
}

resource "kubernetes_namespace_v1" "microservices" {
  metadata {
    name = "microservices"
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
    kind      = "Group"
    name      = "jenkins-deployer"
    api_group = "rbac.authorization.k8s.io"
  }
}

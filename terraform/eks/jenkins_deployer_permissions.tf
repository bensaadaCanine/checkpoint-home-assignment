provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--region",
      "eu-west-1"
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

resource "kubernetes_namespace" "microservices" {
  depends_on = [
    module.eks
  ]

  metadata {
    name = "microservices"
  }
}

resource "kubernetes_cluster_role" "jenkins" {
  depends_on = [
    module.eks,
    module.eks.access_entries # ensures access entry exists first
  ]

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

resource "kubernetes_cluster_role_binding" "jenkins_deployer" {
  depends_on = [
    module.eks,
    module.eks.access_entries # ensures access entry exists first
  ]

  metadata {
    name = "jenkins-deployer-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "Group"
    name      = "jenkins-deployer"
    api_group = "rbac.authorization.k8s.io"
  }
}

# Create secret containing Hetzner Cloud API token
resource "kubernetes_secret" "hcloud-token" {
  metadata {
    name = "hcloud-token-fip-controller"
    namespace = "kube-system"
  }

  data = {
    HCLOUD_IP_FLOATER_HCLOUD_TOKEN = var.hcloud_token
  }
}

# Create fip controller service account
resource "kubernetes_service_account" "hcloud-fip-controller" {
  metadata {
    name = "hcloud-fip-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "hcloud-fip-controller"
    }
  }
}

# Create fip cluster role
resource "kubernetes_cluster_role" "hcloud-fip-controller" {
  metadata {
    name = "hcloud-fip-controller"
    labels = {
      "app.kubernetes.io/name" = "hcloud-fip-controller"
    }
  }
  rule {
    api_groups = [""]
    resources = ["services"]
    verbs = ["get", "watch", "list"]
  }
  rule {
    api_groups = [""]
    resources = ["pods"]
    verbs = ["get", "watch", "list"]
  }
}

# Create fip Cluster Binding Role
resource "kubernetes_cluster_role_binding" "hcloud-fip-controller" {
  metadata {
    name = "hcloud-fip-controller"
    labels = {
      "app.kubernetes.io/name" = "hcloud-fip-controller"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "hcloud-fip-controller"
  }
  subject {
    kind = "ServiceAccount"
    name = "hcloud-fip-controller"
    namespace = "kube-system"
  }
}

# Deploy fip controller
resource "kubernetes_deployment" "hcloud-fip-controller" {
  metadata {
    name = "hcloud-fip-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "hcloud-fip-controller"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "hcloud-fip-controller"
      }
    }
    strategy {
      type = "Recreate"
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "hcloud-fip-controller"
        }
      }
      spec {
        automount_service_account_token = true
        service_account_name = "hcloud-fip-controller"
        container {
          name = "hcloud-fip-controller"
          image = "costela/hcloud-ip-floater:${var.image_tag}"
          env_from {
            secret_ref {
              name = "hcloud-token-fip-controller"
            }
          }
          env_from {
            config_map_ref {
              name = "hcloud-token-fip-controller"
              optional = true
            }
          }
        }
      }
    }
  }
}
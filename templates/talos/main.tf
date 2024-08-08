terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.44.1"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 0.5"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

data "sops_file" "secrets" {
  source_file = "secrets.yaml"
}

module "talos-cluster" {
  source  = "hcloud-talos/talos/hcloud"
  version = "2.10.0"

  hcloud_token = var.hcloud_token

  cluster_name    = "talos-poc"
  datacenter_name = "nbg1-dc3"

  talos_version = "v1.7.5"

  control_plane_count       = 1
  control_plane_server_type = "cax11"

  worker_count       = 2
  worker_server_type = "cax21"

  firewall_kube_api_source  = [data.sops_file.secrets.data["firewall_ip.kube_api"]]
  firewall_talos_api_source = [data.sops_file.secrets.data["firewall_ip.talos_api"]]
  firewall_use_current_ip   = false
}

variable "hcloud_token" {
  type        = string
  description = "Hetzner Cloud API Token"
  sensitive   = true
}

output "talosconfig" {
  value     = module.talos-cluster.talosconfig
  sensitive = true
}

output "kubeconfig" {
  value     = module.talos-cluster.kubeconfig
  sensitive = true
}
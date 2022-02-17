terraform {
  required_providers {
    stackpath = {
      source  = "stackpath/stackpath"
      version = "1.4.0"
    }
  }
}

# declare variables
variable "stack_id" {}
variable "client_id" {}
variable "client_secret" {}

# Configure the StackPath Provider
provider "stackpath" {
  stack_id      = var.stack_id
  client_id     = var.client_id
  client_secret = var.client_secret
}

# Create a new container
resource "stackpath_compute_workload" "minecraft-server" {
  name = "Minecraft Server"
  slug = "minecrafter-server-slug"

  network_interface {
    network = "default"
  }

  container {
    name  = "minecraft-server"
    image = "itzg/minecraft-server"

    resources {
      requests = {
        "cpu"    = "4"
        "memory" = "16Gi"
      }
    }

    port {
      name     = "mc-port"
      port     = 25565
      protocol = "TCP"
    }

    env {
      key   = "EULA"
      value = "True"
    }
  }

  target {
    name             = "us"
    deployment_scope = "cityCode"
    min_replicas     = 1

    selector {
      key      = "cityCode"
      operator = "in"
      values = [
        "MIA",
      ]
    }
  }
}

resource "stackpath_compute_network_policy" "minecraft-server" {
  name        = "Allow Minecraft traffic to Minecraft servers"
  slug        = "minecraft-port-allow"
  description = "A network policy that allows port 25565 used for Minecraft server"
  priority    = 20000

  instance_selector {
    key      = "workload.platform.stackpath.net/workload-slug"
    operator = "in"
    values   = ["minecrafter-server-slug"]
  }

  policy_types = ["INGRESS"]

  ingress {
    action      = "ALLOW"
    description = "Allow port 25565 from Home IP"
    protocol {
      tcp {
        destination_ports = [25565]
      }
    }
    from {
      ip_block {
        cidr = "50.89.245.120/32"
      }
    }
  }
}

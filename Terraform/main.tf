terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "3.0.1-rc6"
    }
  }
}

provider "proxmox" {
  pm_api_url = var.url
  pm_api_token_id = "Terraform@pam!provisioning"
  pm_api_token_secret = var.pm_api_key 
  pm_tls_insecure = true
}

variable "mem_size" {
  description = "Amount of RAM (in MiB) for the virtual machine"
  type        = string
  default     = "2048"
}

variable "cpu_cores" {
  description = "Number of CPU cores for the virtual machine"
  type        = number
  default     = 1
}

variable "vm_count" {
  description = "Number of virtual machines to create"
  type        = number
  default     = 2
}

variable "template_name" {
  description = "Name of the template VM to clone"
  type        = string
  default     = "alma-cloud-init"
}

variable "cloud_init_drive" {
  description = "Name of the cloud-init drive"
  type        = string
  default     = "cloudinit"
}

resource "proxmox_vm_qemu" "test_server" {
  count       = var.vm_count
  name        = "k8s-vm-${count.index + 1}"
  target_node = var.proxmox_host
  memory      = var.mem_size
  cores       = var.cpu_cores
  clone       = var.template_name

  disks {
    ide {
      ide0 {
          disk {
        storage = "local-lvm"
        size    = "12G"
        }
      }
      ide1 {
          cloudinit{
        storage = "local-lvm"
          }
      }
    }
  }

  network {
    id = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  ipconfig0 = "ip=192.168.101.${count.index + 100}/24,gw=192.168.101.1"

  tags = "k8s,terraform"

  ciuser = "user"
  sshkeys = var.ssh_key
}

output "vm_ip" {
  value = [for vm in proxmox_vm_qemu.test_server : vm.ipconfig0]
}


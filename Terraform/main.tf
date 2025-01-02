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

resource "proxmox_vm_qemu" "test_server" {
  count       = var.vm_count
  name        = "k8s-vm-${count.index + 1}"
  target_node = var.proxmox_host
  clone       = var.template_name
  bootdisk = "scsi0"

  scsihw = "virtio-scsi-pci"

  disks {
    scsi {
      scsi0 {
        disk {
          size = "24G"
          storage = "local-lvm"
        }
      }
    }
  }

  network {
    id = 0
    model = "virtio"
    bridge = "vmbr0"
  }

  tags = "k8s"

  sshkeys = <<EOF
  ${var.ssh_key}
  EOF

}

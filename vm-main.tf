resource "libvirt_domain" "vm-main" {
  name       = local.main.name
  memory     = local.main.memory
  vcpu       = local.main.cpu
  cloudinit  = libvirt_cloudinit_disk.commoninit_main.id

  # Required for "wait_for_lease" to work
  qemu_agent = true

  network_interface {
    hostname       = local.main.name
    bridge         = var.network_bridge
    # Wait for IP address
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.vm-qcow2["main"].id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

resource "null_resource" "get_token" {
  provisioner "local-exec" {
    command = "URI=${var.libvirt_uri} DOMAIN=${local.main.name} ${path.module}/get_token.sh"
  }

  depends_on = [null_resource.wait_for_first_vm]
}

data "local_file" "token" {
  depends_on = [null_resource.get_token]
  filename   = ".generated/k3s-token.txt"
}

resource "local_file" "user_data_main" {
  filename = "${path.module}/.generated/user_data_rendered-${local.main.name}.yaml"

  content = templatefile("${path.module}/${var.cloud_init_user_data}", {
    hostname    = local.main.name
    k3s_command = "curl -sfL https://get.k3s.io | sh -"
  })
}

resource "libvirt_cloudinit_disk" "commoninit_main" {
  name           = "commoninit-${local.main.name}.iso"
  user_data      = local_file.user_data_main.content
  network_config = local_file.network_config["main"].content
  pool           = libvirt_pool.vm-storage.name
}

output "main-token" {
  value = trimspace(data.local_file.token.content)
}

output "main-ip" {
  value = libvirt_domain.vm-main.network_interface.0.addresses.0
}

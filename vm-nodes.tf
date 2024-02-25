resource "libvirt_domain" "vm-node" {
  for_each  = local.nodes
  name      = each.value.name
  memory    = each.value.memory
  vcpu      = each.value.cpu
  cloudinit = libvirt_cloudinit_disk.commoninit_nodes[each.key].id

  # Required for "wait_for_lease" to work
  qemu_agent = true

  network_interface {
    hostname       = local.nodes[each.key].name
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
    volume_id = libvirt_volume.vm-qcow2[each.key].id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

resource "local_file" "user_data_nodes" {
  for_each = local.nodes
  filename = "${path.module}/.generated/user_data_rendered-${each.value.name}.yaml"

  content = templatefile("${path.module}/${var.cloud_init_user_data}", {
    hostname    = each.value.name
    k3s_command = "curl -sfL https://get.k3s.io | K3S_URL=https://${libvirt_domain.vm-main.network_interface.0.addresses.0}:6443 K3S_TOKEN=${trimspace(data.local_file.token.content)} sh -"
  })
}

resource "libvirt_cloudinit_disk" "commoninit_nodes" {
  for_each       = local.nodes
  name           = "commoninit-${each.value.name}.iso"
  user_data      = local_file.user_data_nodes[each.key].content
  network_config = local_file.network_config[each.key].content
  pool           = libvirt_pool.vm-storage.name
}

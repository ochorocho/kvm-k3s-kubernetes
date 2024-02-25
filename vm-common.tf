locals {
  main  = var.machines.main
  nodes = {for key, value in var.machines : key => value if key != "main"}
}

resource "libvirt_pool" "vm-storage" {
  name = "cloud-storage"
  type = "dir"
  path = var.storage_pool
}

resource "libvirt_volume" "vm-os-image" {
  name   = "k3s-vm-os"
  pool   = libvirt_pool.vm-storage.name
  source = var.os_uri
}

resource "libvirt_volume" "vm-qcow2" {
  for_each       = var.machines
  name           = each.value.name
  pool           = libvirt_pool.vm-storage.name
  base_volume_id = libvirt_volume.vm-os-image.id
  size           = each.value.size
  format         = "qcow2"
}

resource "local_file" "network_config" {
  for_each = var.machines
  filename = "${path.module}/.generated/network_config_rendered-${each.value.name}.yaml"

  content = templatefile("${path.module}/${var.cloud_init_network_config}", {
    ip_address = each.value.ip_address
    gateway    = each.value.dns
    dns        = each.value.dns
  })
}

# Wait for the "main" VM to run
resource "null_resource" "wait_for_first_vm" {
  provisioner "local-exec" {
    command = "until ping -c1 ${libvirt_domain.vm-main.network_interface.0.addresses.0}; do sleep 5; done"
  }
}

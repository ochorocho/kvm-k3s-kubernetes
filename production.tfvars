# Connect to remote KVM
libvirt_uri = "qemu+ssh://root@192.168.178.114/system?sshauth=privkey"

# Must be a cloud init ready image
os_uri = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64-disk-kvm.img"

# Define bridge "br0" in OMV Network -> Interface using "enp3s0" (second port)
network_bridge = "br0"

# Storage pool path
storage_pool = "/tmp/terraform-provider-libvirt-pool-ubuntu"

machines = {
  # "main" is mandatory. It represents the main node.
  # All others connect to this one.
  "main" = {
    cpu        = 2
    memory     = 4096
    name       = "cloud-main"
    size       = 10737418240
    ip_address = "192.168.178.200"
    dns        = "192.168.178.1"
  }
  "cloud-1" = {
    cpu        = 2
    memory     = 4096
    name       = "cloud-node-1"
    size       = 10737418240
    ip_address = "192.168.178.201"
    dns        = "192.168.178.1"
  }
  "cloud-2" = {
    cpu        = 2
    memory     = 4096
    name       = "cloud-node-2"
    size       = 8737418240
    ip_address = "192.168.178.202"
    dns        = "192.168.178.1"
  }
}

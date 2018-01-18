provider "libvirt" {
    uri = "qemu:///system"
#    uri = "qemu+ssh://fred@192.168.122.188:2222/system"
}

resource "libvirt_cloudinit" "test_cloud_init" {
  name = "test_cloud_init.iso"
  local_hostname = "test_cloud_init"
  ssh_authorized_key = "<your ssh pub key>"
}

# Base OS image to use to create a cluster of different nodes
resource "libvirt_volume" "base_centos" {
  name   = "base_centos_7.qcow2"
  pool   = "default"
# source = "/home/fred/Modèles/CentOS-7-x86_64-GenericCloud-sav.qcow2"
  source = "/var/lib/libvirt/images/CentOS-7-x86_64-GenericCloud.qcow2"
}

# volume to attach to the "master" domain as main disk
resource "libvirt_volume" "test_cloud_init" {
  name           = "test_cloud_init.qcow2"
  pool           = "default"
  base_volume_id = "${libvirt_volume.base_centos.id}"
}

resource "libvirt_network" "test_cloud_init" {
  name = "test_cloud_init"
  addresses = ["10.10.0.0/24"]
  domain = "test_cloud_init.local"
  mode = "nat"
}

resource "libvirt_domain" "test-cloud-init" {
  name = "test_cloud_init"
  vcpu = 2
  cloudinit = "${libvirt_cloudinit.test_cloud_init.id}"

  disk { 
    volume_id = "${libvirt_volume.test_cloud_init.id}"
  }

  network_interface {
    network_id = "${libvirt_network.test_cloud_init.id}"
    #hostname = "test_cloud_init"
    #addresses = ["10.10.0.10"]
    # mac = "AA:BB:CC:11:22:22"
    # wait_for_lease = 1
  }
}

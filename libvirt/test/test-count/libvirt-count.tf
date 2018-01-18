provider "libvirt" {
    uri = "qemu:///system"
#    uri = "qemu+ssh://fred@192.168.122.188:2222/system"
}

resource "libvirt_cloudinit" "test_cloud_init" {
  name = "test_cloud_init.iso"
  local_hostname = "test_cloud_init"
  ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAtlPTSNRN5D8k4eYm9Eank0x5paOWjwqrSDdgCeRJC5uH1TcA125ZiM9fQLefXUko/8Pgs4wTpJLmfWO2wNbfLP2+PsuJItNVKTXorDP3TzTcfTIXpePvUuTwfj9i/jOKWsC6WemuRTXFkG7/Yz8ErLtPcsYrdwC+/+/F5Ad4u7bX932cNe7h3FSfc3kVdunPUhD8FXa/uR4oEHwTRj2HbOqgZto/pV0dOyCi/Ae6BC7DQqEV5fuK++57m+15q8YgRZvfu3SzopliUOBKBdcwZ08n0p8YFsgBxtdcfRhNP6NywPpfrcBvVShiEyyL7texbWsK7YsWNjcNjXRaJFL0iQ== Fred perso"
}

# Base OS image to use to create a cluster of different nodes
resource "libvirt_volume" "base_centos" {
  name   = "base_centos_7.qcow2"
  pool   = "default"
  source = "/var/lib/libvirt/images/CentOS-7-x86_64-GenericCloud.qcow2"
}

# volume to attach to the "master" domain as main disk
resource "libvirt_volume" "test_cloud_init" {
  name           = "test_cloud_init-${count.index}.qcow2"
  pool           = "default"
  base_volume_id = "${libvirt_volume.base_centos.id}"
  count          = 4
}

resource "libvirt_network" "test_cloud_init" {
  name = "test_cloud_init"
  addresses = ["10.10.0.0/24"]
  domain = "test_cloud_init.local"
  mode = "nat"
}

resource "libvirt_domain" "test-cloud-init" {
  name = "test_cloud_init-${count.index}"
  vcpu = 2
  cloudinit = "${libvirt_cloudinit.test_cloud_init.id}"

  disk { 
#    volume_id = "${libvirt_volume.test_cloud_init.id}"
     volume_id = "${element(libvirt_volume.test_cloud_init.*.id, count.index)}"
  }

  network_interface {
    network_id = "${libvirt_network.test_cloud_init.id}"
    #hostname = "test_cloud_init"
    #addresses = ["10.10.0.10"]
    # mac = "AA:BB:CC:11:22:22"
    # wait_for_lease = 1
  }

  count = 4
}

# Libvirt & KVM provider
provider "libvirt" {
    uri = "qemu:///system"
}

# Lab name
variable "labname" { default = "k8s-generic" }

# Number of master to create
variable "master_count" { default = 1 }

# Number of node to create
variable "node_count" { default = 2 }

# Network information
# prefix is the 3 first digit
variable "net_prefix" { default = "10.0.0" }
variable "net" { default = "10.0.0.0/24" }

data "template_file" "user-data" {
  template = "${file("user_data.tpl")}"
  vars {
    user               = "fred"
    ssh_authorized_key = "<your ssh pubkey>"
    password           = "<sha-512 hash password>"
  }
}

# Cloud-init configuration per node
resource "libvirt_cloudinit" "k8s-cloud-init" {
  name               = "${var.labname}.iso"
  user_data          = "${data.template_file.user-data.rendered}"
}

# Base OS image to use to create a cluster of different nodes
resource "libvirt_volume" "base-centos" {
  name   = "base-centos-7.qcow2"
  pool   = "default"
  source = "/var/lib/libvirt/images/CentOS-7-x86_64-GenericCloud.qcow2"
}

# volume to attach to the domain as main disk
resource "libvirt_volume" "k8s-volume" {
  name           = "${count.index < var.master_count ? "${var.labname}-volume-master${count.index + 1}.qcow2" : "${var.labname}-volume-node${count.index - var.master_count + 1}.qcow2" }"
  pool           = "default"
  base_volume_id = "${libvirt_volume.base-centos.id}"
  count          = "${var.master_count + var.node_count}"
}

# virtuel network to attach domain
resource "libvirt_network" "k8s-net" {
  name      = "${var.labname}-net"
  addresses = ["${var.net}"]
  domain    = "nip.io"
  mode      = "nat"
}

# domain
resource "libvirt_domain" "k8s-node" {
  name      = "${count.index < var.master_count ? "${var.labname}-master${count.index + 1}" : "${var.labname}-node${count.index - var.master_count + 1}" }"
  vcpu      = 1
  memory    = 1536
  cloudinit = "${libvirt_cloudinit.k8s-cloud-init.id}"

  cpu {
    # mode = "host-passthrough"
    mode = "host-model"
  }
  
  disk { 
     volume_id = "${element(libvirt_volume.k8s-volume.*.id, count.index)}"
  }

  network_interface {
    network_id = "${libvirt_network.k8s-net.id}"
    hostname   = "${count.index < var.master_count ? "master${count.index + 1}" : "node${count.index - var.master_count + 1}" }"
    addresses  = ["${var.net_prefix}.${count.index + 11}"]
    # fix @mac to avoid conflict with dhcp and to allow change configuration
    #mac            = "52:54:00:2a:01:${count.index + var.master_count + 11}"
    #wait_for_lease = 1
  }

  count = "${var.master_count + var.node_count}"
}

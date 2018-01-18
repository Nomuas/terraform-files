# VMWare Vix provider
provider "vix" {
    product = "fusion"
    verify_ssl = false
}

# Lab name
variable "labname" { default = "k8s-kubespray" }
# Number of master & node to create
variable "master_count" { default = 1 }
variable "node_count" { default = 1 }

resource "vix_vm" "master" {
    name = "${format("${var.labname}-master-%02d", count.index+1)}"
    description = "Terraform VMWare Vix k8s ${format("${var.labname}-master-%02d", count.index+1)}"

    image {
		url = "file:///Users/fred/Downloads/CentOS-7-x86_64-Vagrant-1711_01.VMwareFusion.box"
		checksum = "1c92b17c927b39ee3c02acac142ec0bec1c81a372d187bd058f2ecd5a55530ae"
        checksum_type = "sha256"
    }

    cpus = 2
    # Memory sizes must be provided using IEC sizes such as: kib, ki, mib, mi, gib or gi.
    memory = "2.0gib"
    upgrade_vhardware = true
    gui = false
    tools_init_timeout = "30s"

    network_adapter {
        type = "nat"
        # The MAC address range reserved to VMWare is prefix with 00:50:56.
        mac_address = "00:50:56:2a:2a:${count.index + 11}"
        mac_address_type = "static"
        driver = "vmxnet3"
    }

  count = "${var.master_count}"
}

resource "vix_vm" "node" {
    name = "${format("${var.labname}-node-%02d", count.index+1)}"
    description = "Terraform VMWare Vix k8s ${format("${var.labname}-node-%02d", count.index+1)}"

    image {
		url = "file:///Users/fred/Downloads/CentOS-7-x86_64-Vagrant-1711_01.VMwareFusion.box"
		checksum = "1c92b17c927b39ee3c02acac142ec0bec1c81a372d187bd058f2ecd5a55530ae"
        checksum_type = "sha256"
    }

    cpus = 2
    # Memory sizes must be provided using IEC sizes such as: kib, ki, mib, mi, gib or gi.
    memory = "2.0gib"
    upgrade_vhardware = true
    gui = false
    tools_init_timeout = "30s"

    network_adapter {
        type = "nat"
        # The MAC address range reserved to VMWare is prefix with 00:50:56.
        mac_address = "00:50:56:2a:2a:${count.index + 21}"
        mac_address_type = "static"
        driver = "vmxnet3"
    }

  count = "${var.node_count}"
}

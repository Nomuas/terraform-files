# VMWare Vix provider
provider "vix" {
    product = "fusion"
    verify_ssl = false
}

# Lab name
variable "labname" { default = "k8s-kubespray" }
# Number of master & node to create
variable "master_count" { default = 3 }
variable "node_count" { default = 3 }

resource "vix_vm" "master" {
    name = "${format("${var.labname}-master-%02d", count.index+1)}"
    description = "Terraform VMWare Vix k8s ${format("${var.labname}-master-%02d", count.index+1)}"

    image {
		url = "file:///Users/fred/git/packer-centos-7/builds/vmware-centos7.box"
		checksum = "c53b821d00db0b06637a538b87367f6d95f1f22879ec32f271888da8489030f4"
        checksum_type = "sha256"
    }

    cpus = 2
    # Memory sizes must be provided using IEC sizes such as: kib, ki, mib, mi, gib or gi.
    memory = "2.0gib"
    upgrade_vhardware = false
	gui = "false"
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
		url = "file:///Users/fred/git/packer-centos-7/builds/vmware-centos7.box"
		checksum = "c53b821d00db0b06637a538b87367f6d95f1f22879ec32f271888da8489030f4"
        checksum_type = "sha256"
    }

    cpus = 2
    # Memory sizes must be provided using IEC sizes such as: kib, ki, mib, mi, gib or gi.
    memory = "2.0gib"
    upgrade_vhardware = false
	gui = "false"
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

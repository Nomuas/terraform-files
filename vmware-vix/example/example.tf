provider "vix" {
    product = "fusion"
    verify_ssl = false
}

resource "vix_vm" "tf-example-01" {
    name = "${format("node-%02d", count.index+1)}"
    description = "Terraform VMWARE VIX test"

    # The provider will download, verify, decompress and untar the image. 
    # Ideally you will provide images that have VMware Tools installed already,
    # otherwise the provider will be considerably limited for what it can do.
    image {
	    url = "file:///Users/fred/Downloads/CentOS-7-x86_64-Vagrant-1711_01.VMwareFusion.box"
        checksum = "1c92b17c927b39ee3c02acac142ec0bec1c81a372d187bd058f2ecd5a55530ae"
        checksum_type = "sha256"
    }

    cpus = 2
    # Memory sizes must be provided using IEC sizes such as: kib, ki, mib, mi, gib or gi.
    memory = "1.0gib"
    count = 2
    upgrade_vhardware = true
    tools_init_timeout = "30s"

    # Be aware that GUI does not work if VM is encrypted
    gui = false

    # Whether to enable or disable all shared folders for this VM
    # sharedfolders = false

    # Advanced configuration 
    # network_adapter {
    #     # type can be either "custom", "nat", "bridged" or "hostonly"
	#     type = "custom"
	#     mac_address = "00:50:56:aa:bb:cc"

	#     # mac address type can be "static", "generated" or "vpx"
	#     mac_address_type = "static"

	#     # vswitch is only required when network type is "custom"
	#     vswitch = "${vix_vswitch.vmnet10.name}"
	#     driver = "vmxnet3"
    # }

    network_adapter {
        type = "nat"
        # mac_address = "00:50:56:aa:bb:cc"
        # mac_address_type = "static"
        driver = "vmxnet3"
    }
}

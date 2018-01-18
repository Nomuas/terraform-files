#!/bin/bash

KVM_SERVER=192.168.122.188

terraform destroy -force
rm -f terraform.tfstate*

# Local
sudo bash -c "rm -f /var/lib/libvirt/images/test* /var/lib/libvirt/images/base_centos_7.qcow2"
virsh destroy test_cloud_init
virsh undefine test_cloud_init
virsh net-destroy test_cloud_init
virsh net-undefine test_cloud_init

# Serveur test Fedora
ssh $KVM_SERVER sudo 'bash -c "rm -f /var/lib/libvirt/images/test* /var/lib/libvirt/images/base_centos_7.qcow2"'
virsh -c qemu+ssh://fred@${KVM_SERVER}/system destroy test_cloud_init
virsh -c qemu+ssh://fred@${KVM_SERVER}/system undefine test_cloud_init
virsh -c qemu+ssh://fred@${KVM_SERVER}/system net-destroy test_cloud_init
virsh -c qemu+ssh://fred@${KVM_SERVER}/system net-undefine test_cloud_init

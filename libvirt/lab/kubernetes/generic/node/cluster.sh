#!/bin/bash

#KVM_SERVER=192.168.122.188
NODE_COUNT=4
NODE_PREFIX="k8s-xxyyzz"
IMAGES_DIRECTORY="/var/lib/libvirt/images"

Usage() {
    echo
    echo "Usage : cluster.sh start|stop|clean"
    echo
    echo "Attention, clean supprime toutes les machines virtuelles et les fichiers associés"
    echo
    exit 0
}

if [ $# -ne 1 ]; then
    Usage
fi

case $1 in
    start)
        virsh net-start ${NODE_PREFIX}-net
        for ((i=1; i<=${NODE_COUNT}; i++)); do 
            virsh start ${NODE_PREFIX}-node${i}
        done
        ;;        
    stop)
        for ((i=1; i<=${NODE_COUNT}; i++)); do 
            virsh destroy ${NODE_PREFIX}-node${i}
        done
        virsh net-destroy ${NODE_PREFIX}-net
        ;;
    clean)
        terraform destroy -force
        rm -f terraform.tfstate*
	    rm -fr .terraform

        # Local
        for ((i=1; i<=${NODE_COUNT}; i++)); do 
            virsh destroy ${NODE_PREFIX}-node${i}
            virsh undefine ${NODE_PREFIX}-node${i}
        done
        virsh net-destroy ${NODE_PREFIX}-net
        virsh net-undefine ${NODE_PREFIX}-net
        sudo bash -c "rm -f ${IMAGES_DIRECTORY}/${NODE_PREFIX}* ${IMAGES_DIRECTORY}/base_centos_7.qcow2"

        # Serveur KVM
        # virsh -c qemu+ssh://fred@${KVM_SERVER}/system destroy test_cloud_init
        # virsh -c qemu+ssh://fred@${KVM_SERVER}/system undefine test_cloud_init
        # virsh -c qemu+ssh://fred@${KVM_SERVER}/system net-destroy test_cloud_init
        # virsh -c qemu+ssh://fred@${KVM_SERVER}/system net-undefine test_cloud_init
        # ssh $KVM_SERVER sudo 'bash -c "rm -f /var/lib/libvirt/images/test* /var/lib/libvirt/images/base_centos_7.qcow2"'
        ;;
    *)
        ;;
esac

#!/bin/bash

# Prérequis : 
#   vmware-fusion
#   terraform
#   le provider terraform-provider-vix
#
# Info : sed install with : brew install sed and available through gsed

#set -e

###
# Configuration
###
# Environment variables
export DYLD_LIBRARY_PATH=/Applications/VMware\ Fusion.app/Contents/Public:$DYLD_LIBRARY_PATH
export LD_LIBRARY_PATH=/Applications/VMware\ Fusion.app/Contents/Public:$LD_LIBRARY_PATH
export PATH=$PATH:/Applications/VMware\ Fusion.app/Contents/Library
# Type de produit vmware
VMWARE_TYPE="fusion"
# Number of k8s master & node to create
MASTER_COUNT=1
NODE_COUNT=1
# Vmnet information
VMNET_NUMBER="10"
VMNET_NETWORK="10.30.0.0"
VMNET_NETMASK="255.255.255.0"
# Prefix to use for the VM
LABNAME="k8s-kubespray"
# Golden image checksum is need to find files
IMAGE_URL="file:///Users/fred/Downloads/CentOS-7-x86_64-Vagrant-1711_01.VMwareFusion.box"
IMAGE_CHECKSUM="1c92b17c927b39ee3c02acac142ec0bec1c81a372d187bd058f2ecd5a55530ae"
IMAGES_DIRECTORY="~/.terraform/vix/vms/${IMAGE_CHECKSUM}"
# VMWare binaries
VMNET_CFGCLI="sudo vmnet-cfgcli"
VMNET_CLI="sudo vmnet-cli"
VMRUN="vmrun -T ${VMWARE_TYPE}"

###
# Fonctions
###
Usage() {
    echo
    echo "Usage : cluster.sh install|start|stop|clean"
    echo
    echo "Attention, clean supprime toutes les machines virtuelles et les fichiers associés"
    echo
    exit 0
}

Configure_Vswitch() {
    if [ "$1" == "add" ]; then
        ${VMNET_CFGCLI} vnetcfgadd VNET_${VMNET_NUMBER}_DHCP yes
        ${VMNET_CFGCLI} vnetcfgadd VNET_${VMNET_NUMBER}_HOSTONLY_SUBNET ${VMNET_NETWORK}
        ${VMNET_CFGCLI} vnetcfgadd VNET_${VMNET_NUMBER}_HOSTONLY_NETMASK ${VMNET_NETMASK}
        ${VMNET_CFGCLI} vnetcfgadd VNET_${VMNET_NUMBER}_VIRTUAL_ADAPTER yes
        ${VMNET_CFGCLI} vnetcfgadd VNET_${VMNET_NUMBER}_NAT yes
    else
        ${VMNET_CFGCLI} vnetcfgremove VNET_${VMNET_NUMBER}_DHCP
        ${VMNET_CFGCLI} vnetcfgremove VNET_${VMNET_NUMBER}_HOSTONLY_SUBNET
        ${VMNET_CFGCLI} vnetcfgremove VNET_${VMNET_NUMBER}_HOSTONLY_NETMASK
        ${VMNET_CFGCLI} vnetcfgremove VNET_${VMNET_NUMBER}_VIRTUAL_ADAPTER
        ${VMNET_CFGCLI} vnetcfgremove VNET_${VMNET_NUMBER}_NAT
    fi

    ${VMNET_CLI} --configure
    ${VMNET_CLI} --stop
    ${VMNET_CLI} --start
}

###
# Main
###
if [ $# -ne 1 ]; then
    Usage
fi

case $1 in
    install)
        # Configure vswitch
        Configure_Vswitch add

        # Configure terraform file
        gsed -i "s/^variable \"master_count\" { default =.*$/variable \"master_count\" { default = ${MASTER_COUNT} }/" k8s-terraform.tf
        gsed -i "s/^variable \"node_count\" { default =.*$/variable \"node_count\" { default = ${NODE_COUNT} }/" k8s-terraform.tf
        gsed -i "s|^[[:space:]]*url = .*$|\t\turl = \"${IMAGE_URL}\"|" k8s-terraform.tf
        gsed -i "s/^[[:space:]]*checksum = .*$/\t\tchecksum = \"${IMAGE_CHECKSUM}\"/" k8s-terraform.tf
        gsed -i "s/^variable \"labname\" { default =.*$/variable \"labname\" { default = \"${LABNAME}\" }/" k8s-terraform.tf
        gsed -i "s/^variable \"labname\" { default =.*$/variable \"labname\" { default = \"${LABNAME}\" }/" k8s-terraform.tf    

        # Apply configuration until....it works !
        terraform init
        while [ `vmrun list | grep "${IMAGE_CHECKSUM}/${LABNAME}" | wc -l` != "$(( ${MASTER_COUNT} + ${NODE_COUNT} ))" ]; do
            terraform apply -auto-approve
            sleep 5
        done

        # Change setting of the guest network adapter (sheety provider !)
        $0 stop
        for VM in `eval ls ${IMAGES_DIRECTORY}/${LABNAME}*/*.vmx`; do
            ${VMRUN} setNetworkAdapter ${VM} 0 custom vmnet${VMNET_NUMBER}
        done
        $0 start   
        ;;
    start)
        for VM in `eval ls ${IMAGES_DIRECTORY}/${LABNAME}*/*.vmx`; do
            ${VMRUN} start ${VM} nogui
        done
        ;;
    stop)
        for VM in `vmrun list | grep "${IMAGE_CHECKSUM}/${LABNAME}"`; do
            ${VMRUN} stop ${VM} hard
        done
        ;;
    clean)
        # Remove VM
        terraform destroy -force

        # Remove vswitch
        Configure_Vswitch remove

        # Remove files if necessary
        rm -fr "${IMAGES_DIRECTORY}/${LABNAME}-{master,node}*"
        ;;
    *)
        Usage
esac

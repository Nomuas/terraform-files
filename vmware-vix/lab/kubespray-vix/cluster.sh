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
# Show vm window (true or false)
GUI="false"
# Prefix to use for the VM
LABNAME="k8s-kubespray"
# Number of k8s master & node to create (9 each max)
MASTER_COUNT=3
NODE_COUNT=3
# Vmnet information (fix to /24 for the lab)
VMNET_NUMBER="10"
VMNET_NETWORK_PREFIX="10.30.0"       # Ex : 10.10.0 for the class C 10.10.0.0/24
# Golden image checksum is need to find files (shasum -a256 <file.box>)
IMAGE_URL="file:///Users/fred/git/packer-centos-7/builds/vmware-centos7.box"
IMAGE_CHECKSUM="c53b821d00db0b06637a538b87367f6d95f1f22879ec32f271888da8489030f4"
# IMAGE_URL="file:///Users/fred/Downloads/CentOS-7-x86_64-Vagrant-1711_01.VMwareFusion.box"
# IMAGE_CHECKSUM="1c92b17c927b39ee3c02acac142ec0bec1c81a372d187bd058f2ecd5a55530ae"
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
        ${VMNET_CFGCLI} vnetcfgadd VNET_${VMNET_NUMBER}_HOSTONLY_SUBNET ${VMNET_NETWORK_PREFIX}.0
        ${VMNET_CFGCLI} vnetcfgadd VNET_${VMNET_NUMBER}_HOSTONLY_NETMASK 255.255.255.0
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
        echo "-> Configure VSwitch"
        Configure_Vswitch add

        # Configure terraform file
        echo "-> Configure terraform file"
        gsed -i "s/^variable \"master_count\" { default =.*$/variable \"master_count\" { default = ${MASTER_COUNT} }/" k8s-terraform.tf
        gsed -i "s/^variable \"node_count\" { default =.*$/variable \"node_count\" { default = ${NODE_COUNT} }/" k8s-terraform.tf
        gsed -i "s/^[[:space:]]*gui = .*$/\tgui = \"${GUI}\"/" k8s-terraform.tf
        gsed -i "s|^[[:space:]]*url = .*$|\t\turl = \"${IMAGE_URL}\"|" k8s-terraform.tf
        gsed -i "s/^[[:space:]]*checksum = .*$/\t\tchecksum = \"${IMAGE_CHECKSUM}\"/" k8s-terraform.tf
        gsed -i "s/^variable \"labname\" { default =.*$/variable \"labname\" { default = \"${LABNAME}\" }/" k8s-terraform.tf
        gsed -i "s/^variable \"labname\" { default =.*$/variable \"labname\" { default = \"${LABNAME}\" }/" k8s-terraform.tf    

        # Apply configuration until....it works !
        echo "-> Apply terraform"
        terraform init
        while [ `vmrun list | grep "${IMAGE_CHECKSUM}/${LABNAME}" | wc -l` != "$(( ${MASTER_COUNT} + ${NODE_COUNT} ))" ]; do
            terraform apply -auto-approve
            sleep 5
        done

        # Change setting of the guest network adapter (sheety provider !)
        echo "-> Change guest network adapter (need restart vm)"
        $0 stop
        for VM in `eval ls ${IMAGES_DIRECTORY}/${LABNAME}*/*.vmx`; do
            ${VMRUN} setNetworkAdapter ${VM} 0 custom vmnet${VMNET_NUMBER}
            # ${VMRUN} -gu root -gp changeme runProgramInGuest ${VM} /bin/nmcli con mod eth0 ip4 gw4 ipv4.dns 
        done
        $0 start

        # Wait for the guests to become available (!= start)
        echo "-> Wait for restart"
        sleep 30

        # Force static ip inside the guests
        echo "-> Force static ip inside guests"
        master_count=1
        node_count=1
        for VM in `vmrun list | grep "${IMAGE_CHECKSUM}/${LABNAME}" | sort`; do
            grep -q master ${VM} && ip4=$((10+master_count++)) || ip4=$((20+node_count++))
            ${VMRUN} -gu root -gp changeme runProgramInGuest ${VM} /bin/nmcli con del con-name "eth0"
            ${VMRUN} -gu root -gp changeme runProgramInGuest ${VM} /bin/nmcli con add con-name "eth0" ifname eth0 type ethernet ip4 ${VMNET_NETWORK_PREFIX}.${ip4}/24 gw4 ${VMNET_NETWORK_PREFIX}.2 ipv4.dns ${VMNET_NETWORK_PREFIX}.2
            ${VMRUN} -gu root -gp changeme runProgramInGuest ${VM} /bin/nmcli con up "eth0" iface eth0
            ${VMRUN} -gu root -gp changeme runProgramInGuest ${VM} /bin/nmcli con del "Connexion filaire 1"
        done

        # Wait for change becoming available
        echo "-> Wait for change becoming available"
        sleep 20
        
        # Resume guests ip
        for VM in `vmrun list | grep "${IMAGE_CHECKSUM}/${LABNAME}" | sort`; do
            echo "`echo ${VM} | awk -F'/' '{ print $(NF-1) }'` -> `${VMRUN} -gu root -gp changeme getGuestIPAddress ${VM}`"
        done
        ;;
    start)
        for VM in `eval ls ${IMAGES_DIRECTORY}/${LABNAME}*/*.vmx`; do
            [ "$GUI" == "true" ] && ${VMRUN} start ${VM} || ${VMRUN} start ${VM} nogui
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
        rm -fr .terraform terraform.tfstate*
        ;;
    *)
        Usage
esac

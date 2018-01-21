VIX - API VMWare
========================

Test -> Terraform & VMware
Basé sur API vmware-vix

Provider : https://github.com/hooklift/terraform-provider-vix

#### Infos
```shell
go get github.com/hooklift/terraform-provider-vix
cd $HOME/go/src/github.com/hooklift/terraform-provider-vix
make
make install
cp ~/go/bin/terraform-provider-vix /usr/local/bin
cd git/terraform/vmware-vix/minimal
```

Il faut pointer sur les API VIX fournies avec le logiciel installé ; celles fournies avec le repo ne sont plus compatibles.

```shell
DYLD_LIBRARY_PATH=/Applications/VMware\ Fusion.app/Contents/Public:$DYLD_LIBRARY_PATH
LD_LIBRARY_PATH=/Applications/VMware\ Fusion.app/Contents/Public:$LD_LIBRARY_PATH

terraform init
terraform plan
terraform apply
```

#### Utilisation automatique

```shell
./cluster.sh

Usage : cluster.sh install|start|stop|clean

Attention, clean supprime toutes les machines virtuelles et les fichiers associés
```

**L'iso doit être au format *box* pour être utilisée par le provider.**  
  
**Attention** : Si l’iso est téléchargée, il est possible qu’elle ait un attribut com.apple.quarantine visible via la commande :  
`xattr <filename>`  
Pour supprimer cet attribut :  
`xattr -d <filename>`  

#### Manipuler les vswitchs
Contrairement à la doc, ce n'est pas géré par le provider terraform.
Il faut manipuler les réseaux via le cli : https://thornelabs.net/2013/10/18/manually-add-and-remove-vmware-fusion-virtual-adapters.html

#### Cheatsheet vmrun
_Lister les VM en cours_ : `vmrun -T fusion list`  
  
_Récupérer l'IP d'une VM_ : `vmrun -T fusion -gu root -gp vagrant getGuestIPAddress <fichier vmx>` 
   
_Exécuter un script_ : `vmrun -T fusion -gu root -gp vagrant runScriptInGuest <fichier vmx> /bin/bash /root/test.sh`  
  
_Exécuter un programme_ : `vmrun -T fusion -gu root -gp vagrant runProgramInGuest  <fichier vmx> /bin/nmcli`  

_Modifier un network adapter_ : `vmrun -T fusion setNetworkAdapter <fichier vmx> 0 custom vmnet10`

#### Personnalisation de l'iso ou Packer
Il est possible de trouver des isos toutes faites sur le net [exemple pour *Centos*](http://cloud.centos.org/centos/).  
Cependant, elles n'incluent pas *open-vm-tools* ou les *vmware tools* et ne sont pas personnalisées.  
Il suffit  d'en récupérer une et d'en faire une *"golden image"*.
Pour plus de personnalisation, il reste **[Packer](https://www.packer.io/)** (exemple [ici](https://github.com/Nomuas/packer-centos-7) ).

#### Pense bête
```shell
vmrun -T fusion -gu root -gp changeme runProgramInGuest <VM> /bin/nmcli con del con-name "eth0"
vmrun -T fusion -gu root -gp changeme runProgramInGuest <VM> /bin/nmcli con add con-name "eth0" ifname eth0 type ethernet ip4 10.30.0.21/24 gw4 10.30.0.2 ipv4.dns 10.30.0.2
vmrun -T fusion -gu root -gp changeme runProgramInGuest <VM> /bin/nmcli con up "eth0" iface eth0
vmrun -T fusion -gu root -gp changeme runProgramInGuest <VM> /bin/nmcli con del "Connexion filaire 1"
```
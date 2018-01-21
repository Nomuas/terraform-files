### Exemples de fichiers terraform

Ces fichier servent d'exemple pour générer des VM à travers _libvirt_ et _VMWare Fusion_ ; que le host soit local ou distant.  
Le provider _libvirt_ passe par l'API _libvirt_ et instancie des VM sous KVM.  
Le provider pour vmware fusion utilise l'API VMWare _Vix_.  

En terme de fonctionnalité, le provider libvirt est clairement un cran au dessus de ceux pour virtualbox et vmware.

#### Pré requis
 * un host sous linux ou mac os
 * terraform
 * le provider [libvirt](https://github.com/dmacvicar/terraform-provider-libvirt) ou [vmware-vix](https://github.com/hooklift/terraform-provider-vix) qu'il faudra compiler.

#### A savoir
Le provider _libvirt_ stocke ses images au format _qcow2_.Il est possible de les héberger au format _raw_ dans un pool en LVM à condition de modifier le code en Go du provider et des dépendances (tips : search and sometimes replace;)).

Pour générer sur un serveur linux (pas sur mac os) un hash en SHA-512 :  
`# python -c 'import crypt,getpass; print(crypt.cryp(getpass.getpass(), crypt.mksal(crypt.METHOD_SHA512)))'`

#### TODO
 * Tests sur le provider _vmware-vix_ en cours
 * Mettre en place un script de cluster, à l'image des exemples vmware-vix, pour ceux du provider libvirt plutôt qu'un simple clean.

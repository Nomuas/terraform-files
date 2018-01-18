# Documentation -> https://cloudinit.readthedocs.io/en/latest/topics/examples.html
#

# Add users to the system. Users are added after groups are added.
users:
  - name: ${user}
    primary-group: ${user}
    groups: wheel
    passwd: ${password}
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh-authorized-keys:
      - ${ssh_authorized_key}

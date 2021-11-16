#!/bin/bash

echo "Please ensure the ansible vault password has been exported to the environment, i.e.:"
echo "  $  export VAULT_PASSWORD=\"<SECRET_VAULT_PASSWORD>\""
read -p "Press enter to continue (Ctrl-C to abort)"
echo ""

echo "propogate local IP address of apollo VM to /etc/hosts on servers"
echo "ansible-playbook playbook-set-etc-hosts-ip.yml --inventory-file newapollo.inventory --limit changeipvms"
ansible-playbook playbook-set-etc-hosts-ip.yml --inventory-file newapollo.inventory --limit changeipvms
echo
echo "Done."
echo

echo "set up NFS export for apollo VM"
echo "ansible-playbook playbook-apollo-ubuntu20-nfs-server.yml --inventory-file newapollo.inventory --limit nfsservervms"
ansible-playbook playbook-apollo-ubuntu20-nfs-server.yml --inventory-file newapollo.inventory --limit nfsservervms
echo
echo "Done."
echo 

echo "run combined playbook to build apollo"
echo "NOTE: requires 'apollo_admin_password' set in inventory file or will use default password"
echo "ansible-playbook playbook-apollo-ubuntu20-combined.yml --inventory-file newapollo.inventory --limit newapollovms"
ansible-playbook playbook-apollo-ubuntu20-combined.yml --inventory-file newapollo.inventory --limit newapollovms
echo
echo "Done."
echo 

echo "add apollo instance to monitoring"
echo "ansible-playbook playbook-apollo-ubuntu20-monitor.yml --inventory-file newapollo.inventory --limit monitorservervms"
ansible-playbook playbook-apollo-ubuntu20-monitor.yml --inventory-file newapollo.inventory --limit monitorservervms
echo
echo "Done."
echo 

echo "add apollo instance to list of apollo's to backup"
echo "ansible-playbook playbook-apollo-add-to-backup-server.yml --inventory-file newapollo.inventory --limit backupservervms"
ansible-playbook playbook-apollo-add-to-backup-server.yml --inventory-file newapollo.inventory --limit backupservervms
echo
echo "Done."
echo 

echo "Apollo build complete!"
echo


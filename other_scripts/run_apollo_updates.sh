#!/bin/bash

pushd . > /dev/null

echo "change to playbooks directory to run system updates on VMs..."
cd ~/github-ansible/ansible/playbooks/
pwd
echo

# when a reboot is required, the file /var/run/reboot-required will exist
# the contents of this is what gives the MOTD "*** System restart required ***"
# via /etc/update-motd.d/98-reboot-required
if [ -f /var/run/reboot-required ]; then
    echo "WARNING: System restart required on ansible server - running system updates first:"
    echo "  $ sudo apt update; sudo apt upgrade -y"
    sudo apt update
    sudo apt upgrade -y
    echo
    echo "System updates completed."
    echo
    echo "Please save work in progress and then manually reboot this server with:"
    echo "  'sudo shutdown -r'"
    echo "Then re-run this script to run updates across other hosts."
    echo
    exit 0
fi

echo "run system updates on ubuntu infrastructure and test VMs (this may involve reboots)"
echo "updating apollo-data, apollo-monitor, apollo-portal and ubuntu20-test..."
echo "ansible-playbook playbook-system-updates-ubuntu.yml --limit otherubuntuvms"
ansible-playbook playbook-system-updates-ubuntu.yml --limit otherubuntuvms

echo "run system updates on centos infrastructure and test VMs (this may involve reboots)"
echo "updating apollo-backup and centos-test..."
echo "ansible-playbook playbook-system-updates-centos.yml --limit centosvms"
ansible-playbook playbook-system-updates-centos.yml --limit centosvms

echo "run system updates on all apollo VMs (this may involve reboots)"
echo "ansible-playbook playbook-system-updates-ubuntu.yml --limit apollovms"
ansible-playbook playbook-system-updates-ubuntu.yml --limit apollovms

echo "system updates completed!"
echo "check that all systems are up and running from Nagios:"
echo "    http://nagios.genome.edu.au/nagios4/"

popd > /dev/null


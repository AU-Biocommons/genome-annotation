#!/bin/bash

echo "Note: ansible-sandpit should be manually updated with:"
echo "        $ sudo apt update; sudo apt upgrade -y"
echo "      and rebooted if needed with:"
echo "        $ sudo shutdown -r now"
echo

pushd . > /dev/null

echo "change to playbooks directory to run system updates on VMs..."
cd ~/github-ansible/ansible/playbooks/
pwd
echo

echo "run system updates on centos infrastructure and test VMs (this may involve reboots)"
echo "updating apollo-backup and centos-test..."
echo "ansible-playbook playbook-system-updates-centos.yml --limit centosvms"
ansible-playbook playbook-system-updates-centos.yml --limit centosvms

echo "run system updates on ubuntu infrastructure and test VMs (this may involve reboots)"
echo "updating apollo-data, apollo-monitor, apollo-portal and ubuntu20-test..."
echo "ansible-playbook playbook-system-updates-ubuntu.yml --limit otherubuntuvms"
ansible-playbook playbook-system-updates-ubuntu.yml --limit otherubuntuvms

echo "run system updates on all apollo VMs (this may involve reboots)"
echo "ansible-playbook playbook-system-updates-ubuntu.yml --limit apollovms"
ansible-playbook playbook-system-updates-ubuntu.yml --limit apollovms

echo "system updates completed!"
echo "check that all systems are up and running from Nagios:"
echo "    http://nagios.genome.edu.au/nagios/"

popd > /dev/null


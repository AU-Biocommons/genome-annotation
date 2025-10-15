# Ansible Playbooks

This directory contains the Ansible playbooks, inventory files and apollo build scripts (to simplify and automate running the ansible scripts) for configuring and maintaining all the hosts that make up the Australian Apollo Service. The sub-folder `group_vars` contains definitions for the various inventory groups, and Ansible Vaults in `group_vars/<group>/vault` contain passwords and other credentials required in host builds. Playbooks in `one-offs` are rarely required and often execute only one or two tasks.

There are specific playbooks for building each of the host types that make up the Australian Apollo Service:
- Core infrastructure servers:
    - Backup and deployment server;
    - NFS server;
    - Monitoring server
- Web servers:
    - Apollo Portal
    - JBrowse portal
- Apollo instances
- Sandpit VMs for development and testing

There are a few other non-build related playbooks, such as for running system updates, that will also be covered below.


## Prerequisites

- SSH access to target hosts is required, typically using the keypair defined when VMs are created, and the account running ansible playbooks should configure ssh to connect to hosts with the required username and ssh key.
- Ansible needs to be installed and configured. The `./ansible.cfg` is used to configure the location of the ansible inventatory and roles, and redirects ansible vault operations to use the password script defined in `./.vault_pass`.
- Inventory: `./hosts` (FQDNs and internal shortnames only; no public IPs).
- Secrets: do not commit. Use environment variables or Ansible Vault for any credentials/tokens.


## Configuration

### SSH Configuration

For ease of use, and as the scripts that automate Apollo builds do not explicitly define the private key to use to connect to the destination, the account used for running ansible (typically the ubuntu account on the deployment server) should have its `.ssh/config` configured for connecting to hosts with the required username and ssh key. This is done in `playbook-setup-nectar-deployment-server.yml`, resulting in the following ssh config::
```
# disable ssh agent-loaded identities by default (fixes multi-key auth failures)
Host *
     IdentitiesOnly yes

Host apollo-*
     User ubuntu
     IdentityFile /home/ubuntu/.ssh/apollo-nectar
     IdentitiesOnly yes
     StrictHostKeyChecking no

Host *.genome.edu.au
     User ubuntu
     IdentityFile /home/ubuntu/.ssh/apollo-nectar
     IdentitiesOnly yes
     StrictHostKeyChecking no
```

If ansible is being run from another account, the ssh config should be configured as shown above.


### Ansible Configuration
Ansible is configured with the `ansible.cfg` located in this directory. This currently defines the following locations:
- `inventory`: `./hosts`. The ansible inventory file is located in this directory.
- `roles_path`: `../roles:~/.ansible/roles`. Roles will be searched for in the sibling directory (`ansible/roles`) while the playbooks and ansible configuration are defined in (`ansible/playbooks`).
- `vault_password_file`: `./.vault_pass`. Ansible vault operations run this script which looks for the shell environment variable `VAULT_PASSWORD` to pass to the vault as the requested password. If it is not defined but `VAULT_PASS_ALLOW_NULL` is defined then a dummy password is passed to ansible for those ansible operations that don't require access to the vault.


## Inventory
The main ansible inventory, located in `./hosts` defines all the defined hosts that ansible will perform operations on, along with host groups and variables. The `hosts` file is primarily used when running playbooks that apply updates across many hosts, or for providing a list of hosts within a particular group, such as client apollos. The `hosts` file is *not* used when building new hosts, for which specific host-based inventory files are used.

### Host-based Inventory files
buildapollo3sandpit.inventory
builddeploy.inventory
buildjbrowse.inventory
buildmonitor.inventory
buildmtsandpit.inventory
buildnewportalvms.inventory
buildnfs.inventory
buildsandpit.inventory
buildubuntutest.inventory
buildwebservervms.inventory

buildapollo.template - see Apollo build scripts

## Group Vars
apollovms
changeipvms
jbrowseportalvms
monitorservervms
newapollovms
newmonitorservervms
newportalvms
newservervms
newubuntutestvms
newwebservervms
nfsservervms
otherubuntuvms

### Vaults
`group_vars/newportalvms/vault`
`group_vars/newapollovms/vault`
`group_vars/newmonitorservervms/vault`


## Playbooks

### General Build Playbooks
- base playbook applied to all infrastructure, web server and sanspit VMs prior to running specific playbook-setup-nectar-* playbook
  playbook-base-nectar-server-ubuntu.yml

### Host Specific Build Playbooks
host specific playbooks used to build a host with specific functionality

#### Core infrastructure servers:
- update /etc/hosts on all infrastructure servers
  playbook-set-etc-hosts-ip.yml
- Backup and deployment server
  - install
    playbook-setup-nectar-deployment-server.yml
  - update apollos to backup
    playbook-apollo-add-to-backup-server.yml
- NFS server
  - install
    playbook-setup-nectar-nfs-server.yml
  - update apollos being served from file server
    playbook-apollo-ubuntu-nfs-server.yml
- Monitoring server
  - install
    playbook-monitor-install-grafana-server.yml
  - update VMs being monitored
  playbook-monitor-refresh-sources-and-dashboards.yml

#### Web servers:
- Apollo Portal
  playbook-setup-nectar-portal.yml
- JBrowse portal
  playbook-jbrowse-build-instances-on-portal.yml
  playbook-jbrowse-discover-exports-and-mount.yml

#### Sandpit VMs for development and testing
- apollo sandpit (apollo builds)
  playbook-setup-nectar-sandpit.yml
- apollo3 sandpit
  playbook-setup-nectar-apollo3sandpit.yml
- mtsandpit (Jbrowse2)
  playbook-setup-nectar-mtsandpit.yml

#### Apollo instances
- see Apollo build scripts

## Apollo Playbooks and build scripts
### Playbooks
- build apollo instance
  playbook-build-nectar-apollo.yml
- restore apollo database from backup
  playbook-restore-apollo-db.yml
### Scripts
- main script
  build-newapollo.sh
- supporting scripts called by main script
  build-newapollo-inventory.sh
  build-newapollo-runplaybooks.sh
  build-newapollo-groupadd-apollovms.sh

### Inventory Templates
buildapollo.template


### System Maintenance Playbooks
playbook-system-updates-ubuntu.yml


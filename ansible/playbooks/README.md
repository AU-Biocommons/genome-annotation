# Ansible Playbooks

This directory contains the **Ansible playbooks**, **inventory files** and **Apollo build scripts** (wrappers that simplify running the playbooks) for configuring and maintaining all the hosts that make up the Australian Apollo Service.

- Group variables live in `group_vars/`.
- Ansible Vaults live under `group_vars/<group>/vault` and contain passwords and credentials required during builds.
- Playbooks under `one-offs/` are rarely required and typically execute one or two tasks.

There are specific playbooks for building each of the host types that make up the Australian Apollo Service:
- **Core infrastructure servers**
    - Backup and deployment server
    - NFS server
    - Monitoring server
- **Web servers**
    - Apollo Portal
    - JBrowse portal
- **Apollo instances**
- **Sandpit VMs** for development and testing

Other non-build related playbooks, such as for running system updates, are documented below.


## Prerequisites

- **SSH access** to target hosts is required using the keypair defined at VM creation time.
- **Ansible installed and configured**: `./ansible.cfg` (defines inventory location, roles path, and vault password script).
- **Inventory**: `./hosts` (FQDNs and internal shortnames only; no public IPs).
- **Secrets**: do not commit. Use environment variables and/or Ansible Vault.


## Configuration

### SSH Configuration

For convenience (and because build scripts do not pass an explicit private key), the Ansible control account (typically `ubuntu` on the deployment server) should have an SSH config like below. This is applied by `playbook-setup-nectar-deployment-server.yml`.

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

If running Ansible from a different account, replicate this SSH configuration.


### Ansible Configuration
Ansible is configured with the `ansible.cfg` located in this directory. This currently defines the following locations:
- `inventory`: `./hosts`. The ansible inventory file is located in this directory.
- `roles_path`: `../roles:~/.ansible/roles`. Roles will be searched for in the sibling directory (`ansible/roles`) while the playbooks and ansible configuration are defined in (`ansible/playbooks`).
- `vault_password_file`: `./.vault_pass`. Ansible vault operations run this script which looks for the shell environment variable `VAULT_PASSWORD` to pass to the vault as the requested password. If it is not defined but `VAULT_PASS_ALLOW_NULL` is defined then a dummy password is passed to ansible for those ansible operations that don't require access to the vault.


## Ansible Inventory
The main **ansible inventory**, located in `./hosts` defines managed hosts, host groups and variables. This is primarily used when running playbooks that apply updates across many hosts, or for targetting groups, such as client apollos.

Note: **Host builds do not use `./hosts`**, instead they use **host-based inventory files** (see below).

### Host-based Inventory files
These inventory files are passed to multiple playbooks and are used to configure variables for host builds and for integrating the specified host with other infrastructure servers.

An example is using `changeipvms` with playbook-set-etc-hosts-ip.yml to populate `/etc/hosts` on the infrastructure servers:
```
ansible-playbook playbook-set-etc-hosts-ip.yml --inventory-file buildapollo3sandpit.inventory --limit changeipvms
```

The general format of host inventory files is:
```
[GROUPNAME]
HOST.genome.edu.au

[GROUPNAME:vars]
LOCALVAR=SOME_VALUE

# populate host and local IP in these servers /etc/hosts
[changeipvms]
apollo-backup.genome.edu.au ansible_user=ubuntu admin_group=sudo
apollo-user-nfs.genome.edu.au ansible_user=ubuntu admin_group=sudo
apollo-monitor.genome.edu.au ansible_user=ubuntu admin_group=sudo

[changeipvms:vars]
hostname_for_ip=HOST
private_ip=192.168.0.XY

# configure NFS exports for apollo/jbrowse hosts
[nfsservervms]
apollo-user-nfs.genome.edu.au

[nfsservervms:vars]
# use internal hostname
nfs_client=HOST

# add to apollo-specific backups - apollo hosts only
[backupservervms]
apollo-backup.genome.edu.au

[backupservervms:vars]
apollo_instance_number=XYZ
```

The following are the host inventory files and the host associated with them
- `buildapollo3sandpit.inventory`: apollo3-sandpit inventory
- `builddeploy.inventory`: apollo-backup/apollo-deploy inventory
- `buildjbrowse.inventory`: jbrowse-portal (apollo-user-jbrowse) inventory
- `buildmonitor.inventory`: apollo-monitor inventory
- `buildmtsandpit.inventory`: mt-sandpit (jbrowse2 sandpit) inventory
- `buildnewportalvms.inventory`: inventory used by playbook-deploy-portal.yml to deploy django website on apollo-portal
- `buildnfs.inventory`: apollo-user-nfs inventory
- `buildsandpit.inventory`: apollo-sandpit (apollo2 build VM) inventory
- `buildubuntutest.inventory`: test VM inventory
- `buildwebservervms.inventory`: inventory used for web server builds (apollo-portal)

There is also a `buildapollo.template` which is used to create apollo inventories by the Apollo build scripts.

## Group Vars and Vaults
For each of the groups defined in the inventory files there is a corresponding group directory. At a minimum these contain a `vars` file defining some variables that the playbooks will need, while for host groups that need access to secrets, there will also be a `vault` file.

As an example, `group_vars/apollovms/vars` contains:
```
---
ansible_user: ubuntu
admin_group: sudo
allowed_groups: "ubuntu apollo_admin backup_user"
target_environment: prod
```

- apollovms: default vars for  playbooks run on apollo hosts.
- changeipvms: defines production environment by default for populating `/etc/hosts`.
- jbrowseportalvms: jbrowse-portal (apollo-user-jbrowse) settings.
- monitorservervms: settings for adding hosts to Grafana/Prometheus on apollo-monitor.
- newapollovms: variables needed for building new apollo VMs. Includes a vault.
- newmonitorservervms: variables for building new apollo-monitor. Includes a vault.
- newportalvms: variables for configuring django web portal on apollo-portal. Includes a vault.
- newservervms: default vars for building infrastructure servers.
- newubuntutestvms: default vars for building a new test VM.
- newwebservervms: default vars for building a new web server,
- nfsservervms: default vars for playbooks run on NFS server (apollo-user-nfs).
- otherubuntuvms: default vars for other ubuntu VMs.

### Vaults
- `group_vars/newportalvms/vault`: stores secrets needed to build django apollo-portal website.
- `group_vars/newapollovms/vault`: stores secrets needed to build an apollo instance.
- `group_vars/newmonitorservervms/vault`: stores secrets needed to build Grafana monitor.


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


## Typical build flow (high-level)

1. **Provision VM(s)** with Terraform (see `../../terraform-nectar/README.md`),
2. **Select the appropriate host-based inventory** (e.g. `buildapollosandpit.inventory`, `buildwebservervms.inventory`, `buildnewportalvms.inventory`).
3. **Run playbooks to integrate host with Apollo infrastructure servers**. For example:
    - add local IP to hosts: `ansible-playbook playbook-set-etc-hosts-ip.yml --inventory-file buildapollosandpit.inventory --limit changeipvms`
    - add export for apollo to NFS: `ansible-playbook playbook-apollo-ubuntu-nfs-server.yml --inventory-file buildapollosandpit.inventory --limit nfsservervms`
4.  For infrastructure servers *only*. **Run the base playbook** for baseline OS hardening, adding admins, installing standard sofware, etc.  For example:
    - base build (apollo-portal):  `ansible-playbook playbook-base-nectar-server-ubuntu.yml --inventory-file buildwebservervms.inventory --limit apollo-portal.genome.edu.au`
5. **Run the host-specific setup playbook(s)** for the target role. For example:
    - setup host (apollo-sandpit): `ansible-playbook playbook-setup-nectar-apollosandpit.yml --inventory-file buildapollosandpit.inventory --limit newapollovms`
    - setup host (apollo-portal): `ansible-playbook playbook-setup-nectar-portal.yml --inventory-file buildnewportalvms.inventory --limit apollo-portal.genome.edu.au`
6. **Apply post-build tasks** (backups, monitoring, mounts). For example:
    - add to monitoring (uses `hosts` inventory: `ansible-playbook playbook-monitor-refresh-sources-and-dashboards.yml --limit monitorservervms`
    - add to apollo2 backups: `ansible-playbook playbook-apollo-add-to-backup-server.yml --inventory-file buildsandpit.inventory --limit backupservervms`
7. **Verify**: service reachability, certificates, systemd services, backups and Prometheus targets.



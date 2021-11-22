# genome-annotation - ansible and build scripts

This folder contains the Ansible scripts, inventory files (containing lists of VMs) and build scripts (to simplify running the ansible scripts) for building Apollo instances and performing system updates. The sub-folder `group_vars` contains definitions for the various inventory groups, and an Ansible Vault in `group_vars/newapollovms/vault` that contains passwords required in the build of a new Apollo instance.

# Quick Start
## Setup

Clone the [https://github.com/AU-Biocommons/genome-annotation](git repository) containing this readme and the ansible playbooks, inventory files, build scripts, etc.
    ```
    git clone git@github.com:AU-Biocommons/genome-annotation github-ansible
    ```

Ensure that you have the ssh keys configured for connecting to hosts and servers via the `ubuntu` (apollo VMs and some infrastructure servers) or `centos` user (some infrastructure servers). This can be done with a `$HOME/.ssh/config file` as for example (substitute `<private_key_associated_with_VMs>` with the actual key name and path):
```
Host apollo-???.genome.edu.au
    User ubuntu
    HostName %h
    IdentityFile ~/.ssh/<private_key_associated_with_VMs>
    IdentitiesOnly yes

Host apollo-data.genome.edu.au
    User ubuntu
    HostName %h
    IdentityFile ~/.ssh/<private_key_associated_with_VMs>
    IdentitiesOnly yes

Host apollo-monitor.genome.edu.au
    User centos
    HostName %h
    IdentityFile ~/.ssh/<private_key_associated_with_VMs>
    IdentitiesOnly yes

Host apollo-backup.genome.edu.au
    User centos
    HostName %h
    IdentityFile ~/.ssh/<private_key_associated_with_VMs>
    IdentitiesOnly yes
```

## VM Creation Steps Prior to Build

The following are the steps required in VM creation prior to the Apollo build with Ansible (via the scripts outlined in the next section). This section outlines the procedure in OpenStack, but the same process can be used to create a VM within the [https://nimbus.pawsey.org.au](Nimbus web interface).

When using OpenStack first source the `openrc.sh` file obtained from Nimbus and enter your Nimbus password.

Create a n3.8c32r flavor VM with Ubuntu 20.04 image, with a 40G volume-based root disk and an public floating IP address.
```
openstack server create \
    --flavor c291f88d-6987-424b-bd6b-2b9128595c74 \
    --image 578525b1-f1e3-495d-b673-3a3b9cd32b23 \
    --boot-from-volume 40 \
    --key-name "$keyname" \
    --availability-zone nova \
    --nic net-id='apollo-network' \
    --security-group default \
    --security-group SSH_from_anywhere \
    --security-group Web_access \
    --security-group NRPE_from_local \
    --security-group ICMP_from_local \
    --security-group Prometheus_node_exporter_from_local \
    --security-group Prometheus_postgres_exporter_from_local \
    --security-group Postgresql \
    "$apollo_name"
```
Where `$keyname` is the private key defined in the `$HOME/.ssh/config` filem and `$apollo_name` is the _openstack_ VM name (not public hostname), and should be of the form: `ABC_apollo_XXX_YYYYMMDD`, where _ABC_ is the initials of the person creating the image (eg `JKL` or `NKR`), _XXX_ is the apollo number (001-999, where 999 is reserved for testing) and _YYYYMMDD_ is the date of VM creation.

Note to get ID's of flavor and image for use in VM creation:
+ `openstack flavor list` shows that `8c32r` has ID `c291f88d-6987-424b-bd6b-2b9128595c74`
+ `openstack image list` shows `Pawsey - Ubuntu 20.04 - 2021-02` has ID `578525b1-f1e3-495d-b673-3a3b9cd32b23`

Once the VM has been created, a floating IP needs to be created from the `public external` pool. This is done with:
```
openstack floating ip create 'Public external'
```
Then find the generated floating IP address with (assuming we don't leave floating IP's hanging around):
```
floating_ip="$(openstack floating ip list | grep None | awk '{ print $4 }')"
```
and associate this with the new VM
```
openstack server add floating ip $apollo_name $floating_ip
```
Check that the IP has been associated, and obtain the private (internal) IP address with:
```
openstack server show $apollo_name | grep addresses
```

Once the VM has been built, create the DNS entries for this VM on Cloudflare, with an __A record__ for `apollo-XXX.genome.edu.au` with the floating IP address assigned above (note `Proxy status` should be set to `DNS only`), and a __CNAME__ with the custom host name (for example the lab or organism name of interest) that points to the A record just defined.

The local and public (floating) IP addresses should be obtained and recorded in the "Genome Annotation VMs" along with the apollo number, build date, custom hostnamem etc.

The apollo number, custom hostname and local IP address will all be needed for the ansible-based build outlined in the next section.

An optional step, that can be done now or post-build, is to assign root a password. This is required for root login from the Nimbus console, which can be useful for troubleshooting when there are network issues, for example. To do this, first generate a passphrase with `xkcdpass` (Linux) or `diceware` (Apple) and save as a note in the `Shared-Apollo` folder on LastPass. Then log into the VM and set the password:
```
ssh -i <path_to_private_key> -o IdentitiesOnly=yes ubuntu@apollo-XXX.genome.edu.au
sudo passwd root
```

If the Apollo build is not to be immediately run after the VM is built, it is a good idea to run the system updates manually now, with:
```
sudo apt update
sudo apt upgrade -y
```
This will prevent errors during the build caused by the `unattended-upgrades` process holding the `dpkg` frontend lock.

## Build a New Apollo

The simplest way to build an Apollo instance on an Ubuntu 20.04 instance is to utilise the `build-newapollo.sh` script, which will generate the inventory file for this apollo, run all the ansible playbooks in the correct order and then update the `apollovms` group in the hosts file on completion (for system updates.

To run this, first change into the directory containing the `build-newapollo*` scripts and this readme.

Then set the ansible vault password for `newapollovms` - the vault contains several passwords required for setting up Apollo on the supplied VM.
```
export VAULT_PASSWORD="<SECRET_VAULT_PASSWORD>"
```
Note, to prevent the vault password from being stored in the bash history, precede the `export` command with a space, i.e.
```
 export VAULT_PASSWORD="<SECRET_VAULT_PASSWORD>"
```
This requires `HISTCONTROL=ignoreboth` set in the `.bashrc` (don't put duplicate lines or lines starting with space in the history).

Use generate an _alphanumeric_ password in LastPass for the apollo admin user, and save password as apollo-XXX.genome.edu.au (with URL `https://apollo-XXX.genome.edu.au/apollo/annotator/index` and Username `ops@qfab.org`) in `Shared-Apollo` folder.

Then run the Apollo build with:
```
./build-newapollo.sh -p admin_password apollo_number custom_hostname private_ip_address
```
Where,
+ `-p admin_password` is optional and is used to provide the secret password for the apollo admin user (`ops@qfab.org`) - if it isn't provided, the default apollo admin password will be used;
+ `apollo_number` is 001-998, or 999 (for ansible testing only);
+ `custom_hostname` is an alphanumeric string with '-' allowed within string;
+ `private_ip_address` is the internal network address, in the form `192.168.A.B`

There is an additional two optional arguments:
+ `-d` specifies dry-run - don't build apollo or update hosts file
+ `-a apollovms_hosts_file` - inventory file for existing apollo VMs (by default 'hosts') 

Note that a common cause of build failure is caused by `unattended-upgrades` holding the dpkg frontend lock. If this occurs, log into the VM and issue the command:
```
sudo kill -KILL $(pgrep -u root -f unattended-upgrades)
```
Then re-run the `build-newapollo.sh` script to complete the build.

Once the build is complete, verify the new apollo instance is working from
+ `https:///apollo-XXX.genome.edu.au/apollo`
+ `https://custom_hostname.genome.edu.au/apollo`
and that can log in as `ops@qfab.org` user

## Post Build Steps



## Running System Maintenance

- do manual system updates on centos infrastructure VMs apollo-monitor, apollo-backup
  (ansible playbooks not yet written to do this)
    $ sudo dnf update -y
  then reboot if kernel has been updated
    $ sudo shutdown -r now

- do manual system updates on ansible-sandpit and reboot if needed
  (done separately so it doesn't get rebooted in the middle of updating 'otherubuntuvms')
    $ sudo apt update
    $ sudo apt upgrade -y
    $ sudo shutdown -r now

- log back into ansible-sandpit and change to playbooks directory
    $ cd ~/github-ansible/ansible/playbooks/
- run updates on ubuntu infrastructure VMs
  apollo-data, apollo-portal, mt-sandpit, ansible-sandpit (done above)
    $ ansible-playbook playbook-system-updates-ubuntu.yml --limit otherubuntuvms

- run system updates and reboot on apollo VMs (see note below)
    $ ansible-playbook playbook-system-updates-ubuntu.yml --limit apollovms --check
    $ ansible-playbook playbook-system-updates-ubuntu.yml --limit apollovms

- do updates on test VMs
    $ ansible-playbook playbook-system-updates-ubuntu.yml --inventory-file testvms.inventory --limit ubuntu20testvms
    $ ansible-playbook playbook-system-updates-ubuntu.yml --inventory-file testvms.inventory --limit ubuntu18testvms

- check that all systems are up and apollo's are running from nagios
    http://nagios.genome.edu.au/nagios/

- log in to apollo-portal
    https://apollo-portal.genome.edu.au/user/login
  check if there are any drupal security updates
  (if there are, will also get alert email to ops@qfab.org)
    https://apollo-portal.genome.edu.au/admin/reports/updates


# Ansible Inventory, Groups and Playbooks
## Prod Servers Hosts (Inventory) File
The prod servers are defined in the hosts (inventory) file in this directory [ansible/playbooks/hosts](hosts)

# Before running Ansible Playbooks
Before running any of the playbooks make sure of the following: 

1. Make sure you can ssh into ansible sandpit with your user
2. Make sure ssh config file in your user's home is correctly setup in the the ansible sandpit and can ssh into remote hosts to be accessed by Ansible
    ```
    ~/.ssh/config
    ```
3. Check/update hosts (inventory) file [ansible/playbooks/hosts](hosts) and if required use limit to specify one of the defined host groups (eg `newapollovms`) and/or check options as required:
    ```
    ansible-playbook yourplaybook.yml --limit yourinventory_server_group_name --check
    ```
    In example, the below command will not apply any changes given it's using `--check` option and the target server(s) will be limited by the `--limit` option:

    ```
    ansible-playbook playbook-apollo.yml --limit ubuntu20testvms --check 
    ```
    In example, to apply changes to the tests servers group remove the `--check` option as below:
    ```
    ansible-playbook playbook-apollo.yml --limit ubuntu20testvms 
    ```
    Because this is the `ansible/playbooks` folder it's not recommended to run without the `--limit` option, therefore in order to apply changes to the target servers it would be something like below command:
    ```
    ansible-playbook playbook-apollo.yml --limit ubuntuprodvms
    ``` 
    Note that in some cases one may not want to target all prod VMs, if that's the case then first create a new group in the [ansible/playbooks/hosts](hosts) file and use it to target a selection of servers or only one server

4. If the host group (defined in the inventory file) uses ansible-vault (eg `newapollovms`), then set the vault password in the environment with:
    ```
    export VAULT_PASSWORD="your_secret_vault_password"
    ```
  Host groups that use ansible-vault will have a `group_vars/<host_group_name>/vault` file, along with the `group_vars/<host_group_name>/vars` file that refers to it. There **should** be a note in the inventory file with the host group indicating the requirement for a vault password.

5. Check andible.cfg file and make sure config is as required in this folder [ansible/playbooks/ansible.cfg](ansible.cfg)
   
6. Make sure your local genome-annotation repo is up to date and has the latest version of all ansible roles and playbooks in `ansible/playbooks` folder 
   
7. Read comments in each one of the playbooks to see if any of these requires parameters to be passed in the command line or through the inventory file. For example playbook-apollo-ubuntu20-combined.yml requires the `apollo_subdomain_name` to be set in the inventory, with for example
    ```
    [newapollovms]
    apollo-999.genome.edu.au apollo_subdomain_name=starwars
    ```
or on the command line with:
    ```
    ansible-playbook playbook-apollo-ubuntu20-combined.yml --extra-vars="apollo_subdomain_name=starwars" --verbose --limit newapollovms
    ```


## Order of Running Ansible Playbooks to create an Apollo VM in Ubuntu 20.04 (Simplified)
Please **`Note that the below playbooks will run in all of the test hosts`** defined in the hosts (inventory) file therefore be careful when running the below playbooks. To install and configure an Apollo VM or VMs the following playbooks have to be run in order and these have to be run from the ansible sandpit: 

The usual approach for deployment is to add the hostname to the `newapollovms` group in the inventory file `ansible/playbooks/newapollovm.inventory`, and remove any previous members. For example:

```
[newapollovms]
apollo-999.genome.edu.au
```

or

```
[ubuntu20testvms]
ubuntu20-test.genome.edu.au
```

Then run the playbooks only on the VMs that belong to the group defined in the inventory file, for example to only run on the test VM:

```
ansible-playbook playbook-configure-host.yml --limit ubuntu20testvms
```

Also note that the `--check` option should be used first, and then if no errors are encountered, then the playbook can be run on the new VM to instantiate the changes. There may be some errors encountered with check that are due to changes not actually being made to the playbook - these are expected and can safely be ignored.

## Installing and Configuring a New Apollo instance with Ansible

To install and configure an Apollo VM or VMs the following playbooks should be run in the specified order. These will need to be run from the ansible-sandpit host: 

1. **playbook-set-etc-hosts-ip.yml** 
   1. Run playbook to add/update entries in /etc/hosts file
   2. Modify `changeipvms` host list in inventory file as required
   3. Requires `--limit changeipvms`
   4. Requires the apollo short hostname `apollo-<XXX>` to be defined in the inventory file for the host group. This should be `apollo-999` if `target_environment=test`.
   5.  Requires environment variable `private_ip=192.168.0.<N>` to be defined in the inventory file for the apollo VM
   6. Optionally specify `target_environment=test` in the inventory file for ansible testing

   Please see example inventory configuration below:
    ```
    [changeipvms]
    ansible-sandpit.genome.edu.au ansible_user=ubuntu admin_group=sudo
    apollo-data.genome.edu.au ansible_user=ubuntu admin_group=sudo
    apollo-monitor.genome.edu.au ansible_user=centos admin_group=wheel
    apollo-backup.genome.edu.au ansible_user=centos admin_group=wheel

    [changeipvms:vars]
    private_ip=192.168.0.78
    hostname_for_ip=apollo-999
    target_environment=test
    ```

   The playbook is run as follows:
    ```
   ansible-playbook playbook-set-etc-hosts-ip.yml --limit changeipvms
    ```

2. **playbook-apollo-ubuntu20-nfs-server.yml**
   1. Run NFS playbook to setup a new apollo VM in the NFS server
   2. Modify `nfsservervms` host list in inventory file if required (currently should have only one host which is `apollo-data.genome.edu.au`)
   3.  Requires use of `--limit` to select which host group defined in inventory file will be the target. **`Note that currently there is only one host/group defined in inventory file`** because there is only one NFS server therefore both prod and test will run on the same vm  
   4.  Requires the apollo instance number `apollo_instance_number=<N>` to be defined in the inventory file for the host group. This should be `999` if `target_environment=test`.
   5. Optionally specify `target_environment=test` in the inventory file for ansible testing

   Please see example inventory configuration below:
    ```
    [nfsservervms]
    apollo-data.genome.edu.au

    [nfsservervms:vars]
    apollo_instance_number=999
    target_environment=test
    ```
   
   The playbook is run as follows:
    ```
   ansible-playbook playbook-apollo-ubuntu20-monitor.yml --limit monitorservervms
    ```

3. **playbook-apollo-ubuntu20-combined.yml**
    1.  Requires ansible vault password configured in the environment, with
        ```
        export VAULT_PASSWORD="your_secret_vault_password"
    2.  Requires the `newapollovms` host group to be defined in the inventory file as the target apollo host, `apollo-XXX.genome.edu.au` where `XXX` is the 3 digit apollo number
    3.  Requires the command line option `--limit newapollovms` to be specified to select the target host group defined in the inventory file (above)
    4.  Optionally define `target_environment=test` for ansible testing
    5.  Requires the apollo instance number `apollo_instance_number=<N>` to be defined in the inventory file for the host group. This should be `999` if `target_environment=test`.
    6.  Requires the custom host name to `apollo_subdomain_name=<CUSTOM>` to be defined in the inventory file for the host group
    7.  Optionally define the password of apollo admin user (`ops@qfab.org`) to override the default password specified in the ansible vault. Note the password **cannot** contain special characters. The default password can also be changed manually on login to the apollo web UI. The password can be set on the commandline with:
        `--extra-vars="apollo_admin_password=<APOLLO-ADMIN-USER_PASSWORD>"`
        or in the inventory file, in the `newapollovms` group vars section
        ```
        [newapollovms:vars]
        apollo_admin_password="<APOLLO-ADMIN-USER_PASSWORD>"
        ```
    ```
    8. Optionally define `apollo_version=<VERSION>` in the inventory file to specify a more recent build (the default is `2.6.0`).

   Please see the following example inventory file configuration:
    ```
    [newapollovms]
    apollo-999.genome.edu.au target_environment=test apollo_instance_number=999 apollo_subdomain_name=starwars
    ```

   The playbook is run as follows:
    ```
    ansible-playbook playbook-apollo-ubuntu20-combined.yml --limit newapollovms
    ```

4. **playbook-apollo-ubuntu20-monitor.yml**
   1. Run monitor playbook to add a new apollo VM to Nagios and Grafana monitoring
   2. The playbook requires the use of `--limit monitorservervms` to select the monitoring servers uin the inventory file. **Note that currently there is only one host defined for this group** as there is only a single monitoring server - therefore both prod and test target environments will run on the same server.
   3. Modify `monitorservervms` host list in inventory file if required (currently only `apollo-monitor.genome.edu.au`)
   5.  Optionally define `target_environment=test` for ansible testing
   5.  Requires the apollo instance number `apollo_instance_number=<N>` to be defined in the inventory file for the host group. This should be `999` if `target_environment=test`.
   6.  Requires environment variable `private_ip=192.168.0.<N>` to be defined in the inventory file for the apollo VM

   Please see the following example inventory file configuration:
    ```
    [monitorservervms]
    apollo-monitor.genome.edu.au

    [monitorservervms:vars]
    apollo_instance_number=999
    private_ip=192.168.0.78
    target_environment=test
    ```

   The playbook is run as follows:
    ```
   ansible-playbook playbook-apollo-ubuntu20-monitor.yml --limit monitorservervms
    ```

5. **playbook-apollo-add-to-backup-server.yml**
   1. Run this playbook to add a new apollo VM to backups
   2. The playbook requires the use of `--limit backupservervms` to select the backup server in the inventory file. **Note that currently there is only one host defined for this group** as there is only a single backup server - therefore both prod and test target environments will run on the same server.
   3. Modify `backupservervms` host list in inventory file if required (currently only `apollo-backup.genome.edu.au`)
   5.  Optionally define `target_environment=test` for ansible testing
   5.  Requires the apollo instance number `apollo_instance_number=<N>` to be defined in the inventory file for the host group. This should be `999` if `target_environment=test`.
   6.  Requires environment variable `private_ip=192.168.0.<N>` to be defined in the inventory file for the apollo VM

   Please see the following example inventory file configuration:
    ```
    [backupservervms]
    apollo-backup.genome.edu.au

    [backupservervms:vars]
    apollo_instance_number=999
    private_ip=192.168.0.78
    target_environment=test
    ```

   The playbook is run as follows:
    ```
   ansible-playbook playbook-apollo-add-to-backup-server.yml --limit backupservervms
    ```


# How to create/modify Ansible Roles
For more information see **`README`** file in [ansible/README.md](../ansible/README.md)





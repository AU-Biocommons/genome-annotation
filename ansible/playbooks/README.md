# genome-annotation - this folder defines the state of prod servers 
The state of the prod servers is defined with Ansible

# Prod Servers Hosts (Inventory) File
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
   
7. Read comments in each one of the playbooks to see if any of these requires parameters to be passed in the command line or through the inventory file. For example playbook-apollo-ubuntu20-combined-2.yml requires the `apollo_subdomain_name` to be set in the inventory, with for example
    ```
    [newapollovms]
    apollo-999.genome.edu.au apollo_subdomain_name=starwars
    ```
or on the command line with:
    ```
    ansible-playbook playbook-apollo-ubuntu20-combined-2.yml --extra-vars="apollo_subdomain_name=starwars" --verbose --limit newapollovms
    ```


# Order of Running Ansible Playbooks to create an Apollo VM in Ubuntu 20.04 (Simplified)
Please **`Note that the below playbooks will run in all of the test hosts`** defined in the hosts (inventory) file therefore be careful when running the below playbooks. To install and configure an Apollo VM or VMs the following playbooks have to be run in order and these have to be run from the ansible sandpit: 

The usual approach for deployment is to add the hostname to the `newapollovms` group in the inventory file `ansible/playbooks/hosts`, and remove any previous members. For example:

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

## Installing and Configuring a New Apollo instance

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

3. **playbook-apollo-ubuntu20-combined-1.yml**
    1.  Requires ansible vault password configured in the environment, with
        ```
        export VAULT_PASSWORD="your_secret_vault_password"
        ```
    2.  Requires the `newapollovms` host group to be defined in the inventory file as the target apollo host, `apollo-XXX.genome.edu.au` where `XXX` is the 3 digit apollo number
    3.  Requires the command line option `--limit newapollovms` to be specified to select the target host group defined in the inventory file (above)
    4.  Optionally define `target_environment=test` for ansible testing
    5.  Requires the apollo instance number `apollo_instance_number=<N>` to be defined in the inventory file for the host group. This should be `999` if `target_environment=test`.
    6.  Requires the custom host name to `apollo_subdomain_name=<CUSTOM>` to be defined in the inventory file for the host group
    7. Optionally define `apollo_version=<VERSION>` in the inventory file to specify a more recent build (the default is `2.6.0`).

   Please see the following example inventory file configuration:
    ```
    [newapollovms]
    apollo-999.genome.edu.au target_environment=test apollo_instance_number=999 apollo_subdomain_name=starwars
    ```

   The playbook is run as follows:
    ```
    ansible-playbook playbook-apollo-ubuntu20-combined-1.yml --limit newapollovms
    ```

4. **`Before running playbook-apollo-ubuntu20-combined-2.yml certbot needs to be manually run using below commands`**
    ```
    sudo certbot certonly --nginx --domains <FQDN>
    sudo certbot certonly --nginx --cert-name <FQDN> --domains <FQDN>,<CUSTOM-FQDN>
    ```
    Where `<FQDN>` refers to the full `apollo-*.genome.edu.au` host name
    and `<CUSTOM-FQDN>` refers to the full `relevant-name.genome.edu.au` additional relevant domain name
    This **MUST** be done before nginx is restarted, which would read in a
    configuration pointing to non-existent `/etc/letsencrypt/live/` key and certificate
    Note: If errors due to missing lets encrypt fullchain.pem, the solution is the following:
    ```
    sudo rm /etc/nginx/sites-enabled/<FQDN>.conf
    sudo rm /etc/nginx/sites-enabled/<CUSTOM-FQDN>.conf
    sudo systemctl restart nginx
    sudo certbot certonly --nginx --domains <FQDN>
    sudo ln -s /etc/nginx/sites-available/<FQDN>.conf /etc/nginx/sites-enabled/<FQDN>.conf
    sudo certbot certonly --nginx --cert-name <FQDN> --domains <FQDN>,<CUSTOM-FQDN>
    sudo ln -s /etc/nginx/sites-available/<CUSTOM-FQDN>.conf /etc/nginx/sites-enabled/<CUSTOM-FQDN>.conf
    sudo systemctl restart nginx
    ```

5.  **playbook-apollo-ubuntu20-combined-2.yml**
    1.  Requires ansible vault password configured in the environment, with
        ```
        export VAULT_PASSWORD="your_secret_vault_password"
        ```
    2.  Requires the `newapollovms` host group to be defined in the inventory file as the target apollo host, `apollo-XXX.genome.edu.au` where `XXX` is the 3 digit apollo number
    3.  Requires the command line option `--limit newapollovms` to be specified to select the target host group defined in the inventory file (above)
    4.  Optionally define `target_environment=test` for ansible testing
    5.  Optionally define the password of apollo admin user (`ops@qfab.org`) to override the default password specified in the ansible vault. Note the password **cannot** contain special characters. The default password can also be changed manually on login to the apollo web UI. The password can be set on the commandline with:
        `--extra-vars="apollo_admin_password=<APOLLO-ADMIN-USER_PASSWORD>"`
        or in the inventory file, in the `newapollovms` group vars section
        ```
        [newapollovms:vars]
        apollo_admin_password="<APOLLO-ADMIN-USER_PASSWORD>"
        ```
    6.  Requires the apollo instance number `apollo_instance_number=<N>` to be defined in the inventory file for the host group. This should be `999` if `target_environment=test`.
    7.  Requires the custom host name to `apollo_subdomain_name=<CUSTOM>` to be defined in the inventory file for the host group

   Please see the following example inventory file configuration:
    ```
    [newapollovms]
    apollo-999.genome.edu.au target_environment=test apollo_instance_number=999 apollo_subdomain_name=starwars
    ```

   The playbook is run as follows:
    ```
    ansible-playbook playbook-apollo-ubuntu20-combined-1.yml --limit newapollovms
    ```

6. **playbook-apollo-ubuntu20-monitor.yml**
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

# How to create/modify Ansible Roles
For more information see **`README`** file in [ansible/README.md](../ansible/README.md)





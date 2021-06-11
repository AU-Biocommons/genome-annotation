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

3. Check/update hosts (inventory) file [ansible/playbooks/hosts](hosts) and if required use limit and/or check options as required:
    ```
    ansible-playbook yourplaybook.yml --limit yourinventory_server_group_name --check
    ```
    In example, the below command will not apply any changes given it's using `--check` option and the target server(s) will be limited by the `--limit` option:

    ```
    ansible-playbook playbook-apollo.yml --limit ubuntutestvms --check 
    ```
    In example, to apply changes to the tests servers group remove the `--check` option as below:
    ```
    ansible-playbook playbook-apollo.yml --limit ubuntutestvms 
    ```
    Because this is the `ansible/playbooks` folder it's not recommended to run without the `--limit` option, therefore in order to apply changes to the target servers it would be something like below command:
    ```
    ansible-playbook playbook-apollo.yml --limit ubuntuprodvms
    ``` 
    Note that in some cases one may not want to target all prod VMs, if that's the case then first create a new group in the [ansible/playbooks/hosts](hosts) file and use it to target a selection of servers or only one server

4. Check andible.cfg file and make sure config is as required  in this folder [ansible/playbooks/ansible.cfg](ansible.cfg)
   
5. Make sure your local genome-annotation repo is up to date and has the latest version of all ansible roles and playbooks in `ansible/playbooks` folder 
   
6. Read comments in each one of the playbooks to see if any of these requires parameters to be passed in the command line in example playbook-postgres-set-password.yml requires to pass in password value in the command line:
    ```
    ansible-playbook playbook-postgres-set-password.yml --extra-vars="postgresql_user_password=<type_password_here>" --verbose --limit ubuntuprodvms
    ```


# Order of Running Ansible Playbooks to create an Apollo VM in Ubuntu 20.04 (Simplified)
Please **`Note that the below playbooks will run in all of the test hosts`** defined in the hosts (inventory) file therefore be careful when running the below playbooks. To install and configure an Apollo VM or VMs the following playbooks have to be run in order and these have to be run from the ansible sandpit: 

The usual approach for deployment is to add the hostname to the `newapollovms` group in the inventory file `ansible/playbooks/hosts`, and remove any previous members. For example:

```
[newapollovms]
apollo-007.genome.edu.au
```

or

```
[ubuntutestvms]
ubuntu20-test.genome.edu.au
```

Then run the playbooks only on the VMs that belong to the group defined in the inventory file, for example to only run on the test VM:

```
ansible-playbook playbook-configure-host.yml --limit ubuntutestvms
```

Also note that the `--check` option should be used first, and then if no errors are encountered, then the playbook can be run on the new VM to instantiate the changes. There may be some errors encountered with check that are due to changes not actually being made to the playbook - these are expected and can safely be ignored.

## Installing and Configuring a New Apollo instance

To install and configure an Apollo VM or VMs the following playbooks should be run in the specified order. These will need to be run from the ansible-sandpit host: 

1. **playbook-set-etc-hosts-ip.yml** 
   1. Run playbook to add/update entries in /etc/hosts file
   2. Modify `changeipvms` host list in inventory file as required
   3. Requires `--limit changeipvms`
   4. Requires environment variable `target_environment=<prod or test>` to be defined in the inventory file for the host group
   5.  Requires the apollo short hostname `apollo-<XXX>` to be defined in the inventory file for the host group. This should be `apollo-999` if `target_environment=test`.
   6.  Requires environment variable `private_ip=192.168.0.<N>` to be defined in the inventory file for the apollo VM

   Please see example inventory configuration below:
    ```
    [changeipvms]
    ansible-sandpit.genome.edu.au ansible_user=ubuntu admin_group=sudo
    apollo-data.genome.edu.au ansible_user=ubuntu admin_group=sudo
    apollo-monitor.genome.edu.au ansible_user=centos admin_group=wheel
    apollo-backup.genome.edu.au ansible_user=centos admin_group=wheel

    [changeipvms:vars]
    target_environment=test
    private_ip=192.168.0.78
    hostname_for_ip=apollo-999
    #target_environment=prod
    #private_ip=192.168.0.N
    #hostname_for_ip=apollo-XXX
    ```

   Please see command example below:
    ```
   ansible-playbook playbook-set-etc-hosts-ip.yml --limit changeipvms
    ```

2. **playbook-apollo-ubuntu20-nfs-server.yml**
   1. Run NFS playbook to setup a new apollo VM in the NFS server
   2. Modify `nfsservervms` host list in inventory file if required (currently should have only one host which is `apollo-data.genome.edu.au`)
   3.  Requires use of `--limit` to select which host group defined in inventory file will be the target. **`Note that currently there is only one host/group defined in inventory file`** because there is only one NFS server therefore both prod and test will run on the same vm  
   4.  Requires environment variable `target_environment=<prod or test>` to be defined in the inventory file for the host group
   5.  Requires the apollo instance number `apollo_instance_number=<N>` to be defined in the inventory file for the host group. This should be `999` if `target_environment=test`.

   Please see example inventory configuration below:
    ```
    [nfsservervms]
    apollo-data.genome.edu.au

    [nfsservervms:vars]
    ansible_user=ubuntu
    admin_group=sudo
    #target_environment=prod
    #apollo_instance_number=X
    target_environment=test
    apollo_instance_number=999
    ```
   
   Please see command below:
    ```
   ansible-playbook playbook-apollo-ubuntu20-monitor.yml --limit monitorservervms
    ```

3. **playbook-apollo-ubuntu20-combined-1.yml**
    1.  Requires postgres root password passed in on the command line, with
        `--extra-vars="postgres_docker_root_password=<POSTGRES-ROOT-PASSWORD>"`
    2.  Requires apollo postgres user password passed in on the command line, with
        `-extra-vars="postgresql_user_password=<POSTGRES-APOLLO-PASSWORD>"`
    3.  Requires the apollo postgres user password passed in on the command line , with
        `--extra-vars="prometheus_postgres_exporter_set_conf_password=<POSTGRES-APOLLO-PASSWORD>"`
    4.  Requires use of `--limit` to select which host group defined in inventory file will be the target
    5.  Requires environment variable `target_environment=<prod or test>` to be defined in the inventory file for the host group
    6.  Requires the apollo instance number `apollo_instance_number=<N>` to be defined in the inventory file for the host group. This should be `999` if `target_environment=test`.
    7.  Requires the custom host name to `apollo_subdomain_name=<CUSTOM>` to be defined in the inventory file for the host group

   Please see example inventory configuration below:
    ```
    [newapollovms]
    #apollo-00X.genome.edu.au
    apollo-999.genome.edu.au

    [newapollovms:vars]
    ansible_user=ubuntu
    admin_group=sudo
    allowed_groups="ubuntu apollo_admin backup_user"
    #target_environment=prod
    #apollo_instance_number=X
    #apollo_subdomain_name=subdomain
    target_environment=test
    apollo_instance_number=999
    apollo_subdomain_name=starwars
    ```

   Please see command example below:
    ```
    ansible-playbook playbook-apollo-ubuntu20-combined-1.yml \
    --extra-vars="postgres_docker_root_password=<POSTGRES-ROOT-PASSWORD>" \
    --extra-vars="postgresql_user_password=<POSTGRES-APOLLO-PASSWORD>" \
    --extra-vars="prometheus_postgres_exporter_set_conf_password=<POSTGRES-APOLLO-PASSWORD>" \
    --limit newapollovms
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
    1.  Requires password of apollo admin user (ops@qfab.org) to passed in as a parameter, and the password cannot contain special characters.
        This will be used to protect the apollo application from being commandeered between when apollo is created and when the admin account is registered via the UI Note that the password can be changed to something more permanent on first login.
        `--extra-vars="apollo_admin_password=<APOLLO-ADMIN-USER_PASSWORD>"`
    2.  Requires use of `--limit` to select which host group defined in inventory file will be the target and to make sure this runs for __only one__ server/host at a time
    4.  Requires environment variable `target_environment=<prod or test>` to be defined in the inventory file for the host group
    5.  Requires the apollo instance number `apollo_instance_number=<N>` to be defined in the inventory file for the host group. This should be `999` if `target_environment=test`.
    6.  Requires the custom host name to `apollo_subdomain_name=<CUSTOM>` to be defined in the inventory file for the host group

   Please see command example below:
    ```
    ansible-playbook playbook-apollo-ubuntu20-combined-2.yml --extra-vars="apollo_admin_password=<APOLLO-ADMIN-USER_PASSWORD>" --limit newapollovms
    ```

6. **playbook-apollo-ubuntu20-monitor.yml**
   1. Run monitor playbook to add a new apollo VM to Nagios and Grafana monitoring
   2. Modify `monitorservervms` host list in inventory file if required (currently should have only one host which is `apollo-monitor.genome.edu.au`)
   3.  Requires use of `--limit` to select which host group defined in inventory file will be the target. **`Note that currently there is only one host/group defined in inventory file`** because there is only one monitoring server therefore both prod and test will run on the same vm  
   4.  Requires environment variable `target_environment=<prod or test>` to be defined in the inventory file for the host group
   5.  Requires the apollo instance number `apollo_instance_number=<N>` to be defined in the inventory file for the host group. This should be `999` if `target_environment=test`.
   6.  Requires environment variable `private_ip=192.168.0.<N>` to be defined in the inventory file for the apollo VM

   Please see example inventory configuration below:
    ```
    [monitorservervms]
    apollo-monitor.genome.edu.au

    [monitorservervms:vars]
    ansible_user=centos
    admin_group=wheel
    #target_environment=prod
    #private_ip=192.168.0.N
    #apollo_instance_number=X
    target_environment=test
    private_ip=192.168.0.78
    apollo_instance_number=999
    ```
   
   Please see command below:
    ```
   ansible-playbook playbook-apollo-ubuntu20-monitor.yml --limit monitorservervms
    ```

# How to create/modify Ansible Roles
For more information see **`README`** file in [ansible/README.md](../ansible/README.md)





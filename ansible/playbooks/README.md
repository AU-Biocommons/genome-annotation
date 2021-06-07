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
   1. Run playbbok to add/update entries in /etc/hosts file
   2. Modify `changeipvms` host list in invetory file as required
   3.  Requires environment variable
      `--extra-vars="target_environment=<prod or test>"`
   4. Requires `--limit changeipvms or --limit changeiptestvms`
   
   Please see **`prod`** command example below:
    ```
   ansible-playbook playbook-set-etc-hosts-ip.yml \
   --extra-vars="target_environment=prod" \
   --limit changeipvms
    ```

   Please see **`test`** command example below **`Note that test command requires additional extra vars target_dev_dir`** so it can be tested in a file different to the real `/etc/hosts` file of the target host. It is recommended whenever changes are made to the playbook or roles that a copy of /etc/hosts file is placed in an `alternate path` and test changes in this copied file first:
    ```
   ansible-playbook playbook-set-etc-hosts-ip.yml \
   --extra-vars="target_environment=test" \
   --extra-vars="target_dev_dir=/alternate/path" \
   --limit changeipvms
    ```

2. **playbook-apollo-ubuntu20-nfs-server.yml**
   1. Run NFS playbook to setup a new apollo VM in the NFS server
   2. Modify `nfsservervms` host list in invetory file if required (currently should have only one host which is `apollo-data.genome.edu.au`)
   3. Requires apollo instance number to be passed in on the command line with where `N` is jut a number without padding with zeros 
      `--extra-vars="apollo_instance_number=N"`
   4.  Requires environment variable
      `--extra-vars="target_environment=<prod or test>"`
   5.  Requires use of `--limit` to select which host group defined in inventory file will be the target. **`Note that currently there is only one host/group defined in inventory file`** because there is only one NFS server therefore both prod and test will run on the same vm  
   
   Please see **`prod`** command example below:
    ```
   ansible-playbook playbook-apollo-ubuntu20-nfs-server.yml \
   --extra-vars="apollo_instance_number=8" \
   --extra-vars="target_environment=prod" \
   --limit nfsservervms
    ```
    
   Please see **`test`** command example below **`Note that test command requires additional extra vars "target_dev_domain" and "target_dev_short_machine_name."`** These extra vars are required because test vm does not comply with naming convetion of production apollo vms and are used to override values that are derived in the playbook run. In example when passin in `apollo_instance_number=999` then `apollo-999` would be the derived machine name and it's overriden to `ubuntu20test`:
    ```
   ansible-playbook playbook-apollo-ubuntu20-nfs-server.yml \
   --extra-vars="apollo_instance_number=999" \
   --extra-vars="target_environment=test" \
   --extra-vars="target_dev_domain=ubuntu20-test.genome.edu.au" \
   --extra-vars="target_dev_short_machine_name=ubuntu20-test" \
   --limit nfsservervms
    ```

3. **playbook-apollo-ubuntu20-combined-1.yml**
    1.  Requires postgres root password passed in on the command line, with
        `--extra-vars="postgres_docker_root_password=<POSTGRES-ROOT-PASSWORD>"`
    2.  Requires apollo postgres user password passed in on the command line, with
        `-extra-vars="postgresql_user_password=<POSTGRES-APOLLO-PASSWORD>"`
    3.  Requires the apollo postgres user password passed in on the command line , with
        `--extra-vars="prometheus_postgres_exporter_set_conf_password=<POSTGRES-APOLLO-PASSWORD>"`
    4.  Requires the apollo instance number to be passed in on the command line as N (1-999), with
        `--extra-vars="apollo_instance_number=<N>"`
    5.  Requires the custom host name to be passed in on the command line, with
        `--extra-vars="apollo_subdomain_name=<CUSTOM>"`
    6.  Requires the memory setting for tomcat
        `--extra-vars="target_tomcat_memory=<Xms and Xmx as required>"`
    7.  Requires environment variable
        `--extra-vars="target_environment=<prod or test>"`
    8.  Requires use of `--limit` to select which host group defined in inventory file will be the target
        
   Please see **`prod`** command example below:
    ```
    ansible-playbook playbook-apollo-ubuntu20-combined-1.yml \
    --extra-vars="postgres_docker_root_password=<POSTGRES-ROOT-PASSWORD>" \
    --extra-vars="postgresql_user_password=<POSTGRES-APOLLO-PASSWORD>" \
    --extra-vars="prometheus_postgres_exporter_set_conf_password=<POSTGRES-APOLLO-PASSWORD>" \
    --extra-vars="apollo_instance_number=8" \
    --extra-vars="apollo_subdomain_name=degnan" \
    --extra-vars="target_tomcat_memory=-Xms8g -Xmx12g" \
    --extra-vars="target_environment=prod" \
    --limit newapollovms
    ```

   Please see **`test`** command example below **`Note that test command requires additional extra vars "target_dev_domain" and "target_dev_short_machine_name."`** These extra vars are required because test vm does not comply with naming convetion of production apollo vms and are used to override values that are derived in the playbook run. In example when passin in `apollo_instance_number=999` then `apollo-999` would be the derived machine name and it's overriden to `ubuntu20test`:
    ```
    ansible-playbook playbook-apollo-ubuntu20-combined-1.yml \
    --extra-vars="postgres_docker_root_password=<POSTGRES-ROOT-PASSWORD>" \
    --extra-vars="postgresql_user_password=<POSTGRES-APOLLO-PASSWORD>" \
    --extra-vars="prometheus_postgres_exporter_set_conf_password=<POSTGRES-APOLLO-PASSWORD>" \
    --extra-vars="apollo_instance_number=999" \
    --extra-vars="apollo_subdomain_name=starwars" \
    --extra-vars="target_tomcat_memory=-Xms512m -Xmx2g" \
    --extra-vars="target_environment=test" \
    --extra-vars="target_dev_domain=ubuntu20-test.genome.edu.au" \
    --extra-vars="target_dev_short_machine_name=ubuntu20-test" \
    --limit ubuntu20testvms
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
    1.  Requires number that will be used to construnct default `apollo-*` domain name to be passed in as a parameter
        `--extra-vars="apollo_instance_number=<apollo instance number without leading zeros>"`
    2.  Requires custom `subdomain name` (ie __not__ the default `apollo-*` name) as domain name
        to be passed in as a parameter 
        `--extra-vars="apollo_subdomain_name=<custom subdomain name without .genome.edu.au>"`
    3.  Requires password of apollo admin user (ops@qfab.org) to passed in as a parameter,
        and the password cannot contain special characters.
        This will be used to protect the apollo application from being commandeered
        between when apollo is created and when the admin account is registered via the UI
        Note that the password can be changed to something more permanent on first login.
        `--extra-vars="apollo_admin_password=<APOLLO-ADMIN-USER_PASSWORD>"`
    4.  Requires the use of `--limit` to make sure this runs for __only one__ server/host at a time
        `--limit <APOLLO-FQDN>`
    5.  Requires environment variable
        `--extra-vars="target_environment=<prod or test>"`
    6.  Requires use of `--limit` to select which host group defined in inventory file will be the target

   Please see **`prod`** command example below:
    ```
    ansible-playbook playbook-apollo-ubuntu20-combined-2.yml \
    --extra-vars="apollo_instance_number=8" \
    --extra-vars="apollo_subdomain_name=degnan" \
    --extra-vars="apollo_admin_password=<APOLLO-ADMIN-USER_PASSWORD>" \
    --extra-vars="target_environment=prod" \
    --limit newapollovms
    ```

   Please see **`test`** command example below **`Note that test command requires additional extra vars "target_dev_domain" and "target_dev_short_machine_name."`** These extra vars are required because test vm does not comply with naming convetion of production apollo vms and are used to override values that are derived in the playbook run. In example when passin in `apollo_instance_number=999` then `apollo-999` would be the derived machine name and it's overriden to `ubuntu20test`:
    ```
    ansible-playbook playbook-apollo-ubuntu20-combined-2.yml \
    --extra-vars="apollo_instance_number=999" \
    --extra-vars="apollo_subdomain_name=startwars" \
    --extra-vars="apollo_admin_password=<APOLLO-ADMIN-USER_PASSWORD>" \
    --extra-vars="target_environment=test" \
    --extra-vars="target_dev_domain=ubuntu20-test.genome.edu.au" \
    --extra-vars="target_dev_short_machine_name=ubuntu20-test" \
    --limit ubuntu20testvms
    ```

# How to create/modify Ansible Roles
For more information see **`README`** file in [ansible/README.md](../ansible/README.md)





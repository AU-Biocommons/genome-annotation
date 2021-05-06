# genome-annotation - this folder defines the state of prod servers 
The state of the prod servers is defined with Ansible

# Prod Servers Hosts (Inventory) File
The prod servers are defined in the hosts (inventory) file in this directory [ansible-prod/hosts](hosts)

# Before running Ansible Playbooks
Before running any of the playbooks make sure of the following: 

1. Make sure you can ssh into ansible sandpit with your user
2. Make sure ssh config file in your user's home is correctly setup in the the ansible sandpit and can ssh into remote hosts to be accessed by Ansible
    ```
    ~/.ssh/config
    ```

3. Check/update hosts (inventory) file [ansible-prod/hosts](hosts) and if required use limit and/or check options as required:
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
    Because this is the `ansible-prod` folder it's not recommended to run without the `--limit` option, therefore in order to apply changes to the target servers it would be something like below command:
    ```
    ansible-playbook playbook-apollo.yml --limit ubuntuprodvms
    ``` 
    Note that in some cases one may not want to target all prod VMs, if that's the case then first create a new group in the [ansible-prod/hosts](hosts) file and use it to target a selection of servers or only one server

4. Check andible.cfg file and make sure config is as required  in this folder [ansible-prod/ansible.cfg](ansible.cfg)
   
5. Make sure your local genome-annotation repo is up to date and has the latest version of all ansible roles and playbooks in `ansible-prod` folder 
   
6. Read comments in each one of the playbooks to see if any of these requires parameters to be passed in the command line in example playbook-postgres-set-password.yml requires to pass in password value in the command line:
    ```
    ansible-playbook playbook-postgres-set-password.yml --extra-vars="postgresql_user_password=<type_password_here>" --verbose --limit ubuntuprodvms
    ```


# Order of Running Ansible Playbooks to create an Apollo VM in Ubuntu 20.04 (Simplified)
Please **`Note that the below playbooks will run in all of the test hosts`** defined in the hosts (inventory) file therefore be careful when running the below playbooks. To install and configure an Apollo VM or VMs the following playbooks have to be run in order and these have to be run from the ansible sandpit: 

The usual approach for deployment is to add the hostname to the `newapollovms` group in the inventory file `ansible-prod/hosts`, and remove any previous members. For example:

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

1. **playbook-apollo-ubuntu20-combined-1.yml**
    1.  Requires postgres root password passed in on the command line, with
        `--extra-vars="postgres_docker_root_password=<POSTGRES-ROOT-PASSWORD>"`
    2.  Requires apollo postgres user password passed in on the command line, with
        `-extra-vars="postgresql_user_password=<POSTGRES-APOLLO-PASSWORD>"`
    3.  Requires the apollo postgres user password passed in on the command line , with
        `--extra-vars="prometheus_postgres_exporter_set_conf_password=<POSTGRES-APOLLO-PASSWORD>"`
        
    Please see example command below:
    ```
    ansible-playbook playbook-apollo-ubuntu20-combined-1.yml \
    --extra-vars="postgres_docker_root_password=<POSTGRES-ROOT-PASSWORD>" \
    --extra-vars="postgresql_user_password=<POSTGRES-APOLLO-PASSWORD>" \
    --extra-vars="prometheus_postgres_exporter_set_conf_password=<POSTGRES-APOLLO-PASSWORD>" \
    --limit newapollovms
    ```

2. **`Before running playbook-apollo-ubuntu20-combined-2.yml certbot needs to be manually run using below commands`**
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

3.  **playbook-apollo-ubuntu20-combined-2.yml**
    1.  Requires number that will be used to construnct default `apollo-*` domain name to be passed in as a parameter
        `--extra-vars="nginx_set_conf_apollo_number=<apollo instance number without leading zeros>"`
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

    Please see example command below:
    ```
    ansible-playbook playbook-apollo-ubuntu20-combined-2.yml \
    --extra-vars="nginx_set_conf_apollo_number=8" \
    --extra-vars="apollo_subdomain_name=degnan" \
    --extra-vars="apollo_admin_password=<APOLLO-ADMIN-USER_PASSWORD>" \
    --limit apollo-008.genome.edu.au
    ```


# Order of Running Ansible Playbooks to create an Apollo VM in Ubuntu 20.04
Please **`Note that the below playbooks will run in all of the prod hosts`** defined in the hosts (inventory) file therefore be careful when running the below playbooks! The `--limit` option should be used, with the name of the apollo instance (for example `apollo-007`), or group containing a single host (`newapollovms` or `ubuntutestvms`).

### Required
1. playbook-configure-host-ubuntu20.yml
2. playbook-add-admin-keys-ubuntu.yml
3. playbook-create-admin-users-groups-logins-ubuntu.yml
4. playbook-apollo-ubuntu20.yml
    1.  Requires postgres root password passed in on the command line, with
        `--extra-vars="postgres_docker_root_password=<POSTGRES-ROOT-PASSWORD>"`
    2.  Requires apollo postgres user password passed in on the command line, with
        `-extra-vars="postgresql_user_password=<POSTGRES-APOLLO-PASSWORD>"`
5. playbook-configure-ufw-ubuntu.yml
6. playbook-prometheus-exporters-ubuntu20.yml
7. playbook-prometheus-exporters-set-conf.yml
    1.  Requires the apollo postgres user password passed in on the command line , with
        `--extra-vars="prometheus_postgres_exporter_set_conf_password=<POSTGRES-APOLLO-PASSWORD>"`
8. **`Before running playbook-nginx-set-conf.yml certbot needs to be manually run using below command`**
    ```
    sudo certbot certonly --nginx --domains <FQDN>
    ```
    Where `<FQDN>` refers to the full `apollo-*.genome.edu.au` host name
    This **MUST** be done before nginx is restarted, which would read in a
    configuration pointing to non-existent `/etc/letsencrypt/live/` key and certificate
    Note: If errors due to missing lets encrypt fullchain.pem, the solution is the following:
    ```
    sudo rm /etc/nginx/sites-enabled/<FQDN>.conf
    sudo systemctl restart nginx
    sudo certbot certonly --nginx --domains <FQDN>
    sudo ln -s /etc/nginx/sites-available/<FQDN>.conf /etc/nginx/sites-enabled/<FQDN>.conf
    ```
9. **`Before running playbook-nginx-add-domain.yml certbot needs to be manually run again below command`**
    ```
    sudo certbot certonly --nginx --cert-name <FQDN> --domains <FQDN>,<CUSTOM-FQDN>
    ```
    Where `<FQDN>` refers to the full `apollo-*.genome.edu.au` host name
    and `<CUSTOM-FQDN>` refers to the full `relevant-name.genome.edu.au` additional relevant domain name
    This **MUST** be done before nginx is restarted, which would read in a
    configuration pointing to non-existent `/etc/letsencrypt/live/` key and certificate
    Note: If errors due to missing lets encrypt fullchain.pem, the solution is the following:
    ```
    sudo rm /etc/nginx/sites-enabled/<CUSTOM-FQDN>.conf
    sudo systemctl restart nginx
    sudo certbot certonly --nginx --cert-name <FQDN> --domains <FQDN>,<CUSTOM-FQDN>
    sudo ln -s /etc/nginx/sites-available/<CUSTOM-FQDN>.conf /etc/nginx/sites-enabled/<CUSTOM-FQDN>.conf
    ```
10. playbook-nginx-set-conf.yml 
    1.  requires domain name to be passed in as a parameter
        `--extra-vars="nginx_set_conf_apollo_number=<FQDN>"`
    1.  requires to use --limit to make sure this runs for `only one` server/host at a time
11. playbook-nginx-add-domain.yml
    1.  Requires custom `host name` (ie __not__ the default `apollo-*` name) as domain name
        to be passed in as a parameter, along with original apollo host name, with
        `--extra-vars="nginx_conf_domain_name=<APOLLO-FQDN>"`
        `--extra-vars="apollo_subdomain_name=<CUSTOM-FQDN>"`
    2.  Requires the use of `--limit` to make sure this runs for __only one__ server/host at a time
        `--limit <APOLLO-FQDN>`
12. playbook-apollo-restart-services.yml
13. **`Wait 3mins to allow apollo database tables to be created`**
14. playbook-apollo-docker-postgres-create-admin.yml
    1.  Requires password of apollo admin user (ops@qfab.org) to passed in as a parameter,
        and the password cannot contain special characters.
        This will be used to protect the apollo application from being commandeered
        between when apollo is created and when the admin account is registered via the UI
        Note that the password can be changed to something more permanent on first login.
        `--extra-vars="apollo_admin_password=<type_password_here>"`
15. playbook-update-base-ubuntu.yml
    1.  This playbook will do a reboot at the end

### Optional
#### If apollo user password needs to be changed 
1. playbook-apollo-docker-postgres-set-password.yml
    1.  Can also be run ad-hoc following above instructions
#### If more than one additional domains are required
2. playbook-nginx-add-domain.yml
    1.  Can also be run ad-hoc following above instructions
    2.  Ensuring this playbook is run for only one target host at anyone time

# Order of Running Ansible Playbooks to create an Apollo VM in Ubuntu 18.04
Please **`Note that the below playbooks will run in all of the prod hosts`** defined in the hosts (inventory) file therefore be careful when running the below playbooks. The limit option can be used if required. In example, the below command will run in all VMs in inventory file:

```
ansible-playbook playbook-configure-host.yml 
```

While the below command will run in VMs that belong to a group (name tag) defined in the inventory file, in the example case below in only the test VMs:

```
ansible-playbook playbook-configure-host.yml --limit ubuntutestvms
```

To install and configure an Apollo VM or VMs the following playbooks have to be run in order and these have to be run from the ansible sandpit: 

1. playbook-configure-host.yml
2. playbook-add-admin-keys-ubuntu.yml
3. playbook-create-admin-users-groups-logins-ubuntu.yml
4. playbook-apollo.yml
5. playbook-configure-ufw-ubuntu.yml
6. playbook-prometheus-exporters-ubuntu.yml **`Note this playbook is broken since latest ubuntu 18 image update in pawsey`**
7. playbook-prometheus-exporters-set-conf.yml
    1. requires password passed in as command line 
    `--extra-vars="prometheus_postgres_exporter_set_conf_password=<POSTGRES-APOLLO-PASSWORD>"`
8. playbook-postgres-set-password.yml
    1. requires password passed in as command line
    `--extra-vars="postgresql_user_password=<POSTGRES-APOLLO-PASSWORD>"`
9.  **`Before running playbook-nginx-set-conf.yml certbot needs to be manually run using below command`**
    ```
    sudo certbot certonly --nginx --domains <FQDN>
    ```
    Where `<FQDN>` refers to the full `apollo-*.genome.edu.au` host name
    This **MUST** be done before nginx is restarted, which would read in a
    configuration pointing to non-existent `/etc/letsencrypt/live/` key and certificate
    Note: If errors due to missing lets encrypt fullchain.pem, the solution is the following:
    ```
    sudo rm /etc/nginx/sites-enabled/<FQDN>.conf
    sudo systemctl restart nginx
    sudo certbot certonly --nginx --domains <FQDN>
    sudo ln -s /etc/nginx/sites-available/<FQDN>.conf /etc/nginx/sites-enabled/<FQDN>.conf
    ```
10. **`Before running playbook-nginx-add-domain.yml certbot needs to be manually run again below command`**
    ```
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
    sudo certbot certonly --nginx --cert-name <FQDN> --domains <FQDN>,<CUSTOM-FQDN>
    sudo ln -s /etc/nginx/sites-available/<FQDN>.conf /etc/nginx/sites-enabled/<FQDN>.conf
    sudo ln -s /etc/nginx/sites-available/<CUSTOM-FQDN>.conf /etc/nginx/sites-enabled/<CUSTOM-FQDN>.conf
    ```
11. playbook-nginx-set-conf.yml
    1.  requires domain name to be passed in as a parameter
        `--extra-vars="nginx_set_conf_apollo_number=<FQDN>"`
    2.  requires to use --limit to make sure this runs for `only one` server/host at a time
12. playbook-nginx-add-domain.yml
    1.  Requires custom `host name` (ie __not__ the default `apollo-*` name) as domain name
        to be passed in as a parameter, along with original apollo host name, with
        `--extra-vars="nginx_conf_domain_name=<APOLLO-FQDN>"`
        `--extra-vars="apollo_subdomain_name=<CUSTOM-FQDN>"`
    2.  Requires the use of `--limit` to make sure this runs for __only one__ server/host at a time
        `--limit <APOLLO-FQDN>`
13. playbook-apollo-restart-services.yml
14. playbook-update-base-ubuntu.yml
    1.  This playbook will do a reboot at the end


# How to create/modify Ansible Roles
For more information see **`README`** file in [ansible/README.md](../ansible/README.md)





# genome-annotation - this folder defines the state of test servers 
The state of the test servers is defined with Ansible

# Test Servers Hosts (Inventory) File
The test servers are defined in the hosts (inventory) file in this directory [ansible-test/hosts](hosts)

# Before running Ansible Playbooks
Before running any of the playbooks make sure of the following: 

1. Make sure you can ssh into ansible sandpit with your user
2. Make sure ssh config file in your user's home is correctly setup in the the ansible sandpit and can ssh into remote hosts to be accessed by Ansible
    ```
    ~/.ssh/config
    ```

3. Check/update hosts (inventory) [ansible-test/hosts](hosts) file and if required use limit and/or check options as required:
    ```
    ansible-playbook yourplaybook.yml --limit yourinventory_server_group_name --check
    ```
    In example, the below command will not apply any changes given it's using `--check` option and the target server(s) will be limited by the `--limit` option:

    ```
    ansible-playbook playbook-apollo.yml --limit ubuntutestvms --check 
    ```
    In example, to apply changes remove the `--check` option as below:
    ```
    ansible-playbook playbook-apollo.yml --limit ubuntutestvms 
    ```
    Because this is the `ansible-test` folder is relatively safe but still recommended to always narrow the target servers by using the `--limit` option however if one intention is to target all tests servers then it would be something like below command:
    ```
    ansible-playbook playbook-apollo.yml 
    ``` 

4. Check andible.cfg file and make sure config is as required  in this folder [ansible-test/ansible.cfg](ansible.cfg)
   
5. Make sure your local genome-annotation repo is up to date and has the latest version of all ansible roles and playbooks in `ansible-test` folder 
   
6. Read comments in each one of the playbooks to see if any of these requires parameters to be passed in the command line in example playbook-postgres-set-password.yml requires to pass in password value in the command line:
    ```
    ansible-playbook playbook-postgres-set-password.yml --extra-vars="postgresql_user_password=<type_password_here>" --verbose --limit ubuntutestvms
    ```


# Order of Running Ansible Playbooks to create an Apollo VM in Ubuntu 20.04 (Simplified)
Please **`Note that the below playbooks will run in all of the test hosts`** defined in the hosts (inventory) file therefore be careful when running the below playbooks. To install and configure an Apollo VM or VMs the following playbooks have to be run in order and these have to be run from the ansible sandpit: 

1. **playbook-set-etc-hosts-ip.yml** 
   1. Run playbbok to add/update entries in /etc/hosts file
   2. Modify `changeiptestvms` host list in invetory file as required
   3. Requires `--limit changeiptestvms`
   
   Please see command example below:
    ```
   ansible-playbook playbook-set-etc-hosts-ip.yml --limit changeiptestvms
    ```

2. **playbook-apollo-ubuntu20-nfs-server.yml**
   1. Run NFS playbook to setup a new apollo VM in the NFS server
   2. Modify `nfsservertest` host list in invetory file if required (currently should have only one host which is `apollo-data.genome.edu.au`)
   3. Requires apollo instance number to be passed in on the command line with `--extra-vars="apollo_instance_number=N"` where `N` is jut a number without padding with zeros and also requires `--limit nfsservertest`
   
   Please see command example below:
    ```
   ansible-playbook playbook-apollo-ubuntu20-nfs-server.yml --extra-vars="apollo_instance_number=8" --limit nfsservertest
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
        `--extra-vars="apollo_instance_number=<CUSTOM>"`
    
    Please see example command below:
    ```
    ansible-playbook playbook-apollo-ubuntu20-combined-1.yml \
    --extra-vars="postgres_docker_root_password=<POSTGRES-ROOT-PASSWORD>" \
    --extra-vars="postgresql_user_password=<POSTGRES-APOLLO-PASSWORD>" \
    --extra-vars="prometheus_postgres_exporter_set_conf_password=<POSTGRES-APOLLO-PASSWORD>" \
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
    
    Please see example command below:
    ```
    ansible-playbook playbook-apollo-ubuntu20-combined-2.yml \
    --extra-vars="apollo_instance_number=20" \
    --extra-vars="apollo_subdomain_name=startwars" \
    --extra-vars="apollo_admin_password=<APOLLO-ADMIN-USER_PASSWORD>" \
    --limit ubuntu20-test.genome.edu.au
    ```

# How to create/modify Ansible Roles
For more information see **`README`** file in [ansible/README.md](../ansible/README.md)





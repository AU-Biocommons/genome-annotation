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

# Order of Running Ansible Playbooks to create an Apollo VM in Ubuntu 20.04
Please **`Note that the below playbooks will run in all of the test hosts`** defined in the hosts (inventory) file therefore be careful when running the below playbooks. To install and configure an Apollo VM or VMs the following playbooks have to be run in order and these have to be run from the ansible sandpit: 

1. playbook-configure-host-ubuntu20.yml
2. playbook-add-admin-keys-ubuntu.yml
3. playbook-setup-admin-users-groups-logins-ubuntu.yml
4. playbook-apollo-ubuntu20.yml
    1. requires postgres root password passed in as command line
    2. requires apollo postgres user password passed in the command line
5. playbook-configure-ufw-ubuntu.yml
6. playbook-prometheus-exporters-ubuntu.yml
7. playbook-prometheus-exporters-set-conf.yml
    1. requires password passed in as command line 
8. **`Before running the following playbooks it's required to manually run certbot`**
9.  playbook-nginx-set-conf.yml
    1.  requires domain name to be passed in as a parameter
    2.  requires to use --limit to make sure this runs for `only one` server/host at a time
10. playbook-apollo-restart-services.yml
11. playbook-update-base-ubuntu.yml
    1.  This playbook will do a reboot at the end


# Order of Running Ansible Playbooks to create an Apollo VM in Ubuntu 18.04
Please **`Note that the below playbooks will run in all of the test hosts`** defined in the hosts (inventory) file therefore be careful when running the below playbooks. To install and configure an Apollo VM or VMs the following playbooks have to be run in order and these have to be run from the ansible sandpit: 

1. playbook-configure-host.yml
2. playbook-add-admin-keys-ubuntu.yml
3. playbook-setup-admin-users-groups-logins-ubuntu.yml
4. playbook-apollo.yml
5. playbook-configure-ufw-ubuntu.yml
6. playbook-prometheus-exporters-ubuntu.yml
7. playbook-prometheus-exporters-set-conf.yml
    1. requires password passed in as command line 
8. playbook-postgres-set-password.yml
    1. requires password passed in as command line
9. **`Before running the following playbooks it's required to manually run certbot`**
10. playbook-nginx-set-conf.yml
    1.  requires domain name to be passed in as a parameter
    2.  requires to use --limit to make sure this runs for `only one` server/host at a time
11. playbook-apollo-restart-services.yml
12. playbook-update-base-ubuntu.yml
    1.  This playbook will do a reboot at the end


# How to create/modify Ansible Roles
For more information see **`README`** file in [ansible/README.md](../ansible/README.md)





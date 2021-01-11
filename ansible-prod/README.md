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
4. Check andible.cfg file and make sure config is as required  in this folder [ansible-prod/ansible.cfg](ansible.cfg)
   
5. Make sure your local genome-annotation repo is up to date and has the latest version of all ansible roles and playbooks in `ansible-prod` folder 
   
6. Read comments in each one of the playbooks to see if any of these requires parameters to be passed in the command line in example playbook-postgres-set-password.yml requires to pass in password value in the command line:
    ```
    ansible-playbook playbook-postgres-set-password.yml --extra-vars="postgresql_user_password=<type_password_here>" --verbose --limit ubuntuprodvms
    ```

# Order of Ansible Playbooks to create Apollo VM
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





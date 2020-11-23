# genome-annotation - this folder defines the state of live and/or test servers 
We define the state of the live and/or test servers with Ansible

We run Ansible in two different locations 
1. ansible (Live or test servers)
2. local_dev (Vagrant)

See local_dev folder for more details. Please be **Very Careful!** when
running any of the ansible playbooks in the ansible folder as these may
impact live (production) apollo VMs. For running any of the playbooks in
this folder follow the below instructions

1. Make sure your ssh config file is correctly setup in the host from
   where the ansible playbook will be run
    ```
    ~/.ssh/config
    ```

2. Run the below command
    ```
    ansible-playbook yourplaybook.yml --limit yourinventory_server_group_name --check
    ```

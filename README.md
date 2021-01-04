# genome-annotation
Australian Biocommons Genome Annotation (Apollo).  

# Ansible

[Ansible](https://www.ansible.com/) is an automation tool for defining the target state of a host VM. Tasks to be run are specified using YAML.
1. Tasks are the atomic changes made to a host VM. 
2. Tasks are grouped into [roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html).
3. Roles can be used by [playbooks](https://docs.ansible.com/ansible/latest/user_guide/playbooks.html) to make the steps for each system easy to understand and define.

# Structure of the genome-annotation repo
The structure of this repo is as below: 

1. The **ansible-test** folder is virtually identical to its counterpart **ansible-prod** folder. The difference is in the hosts (inventory) file and as its name suggests the hosts files has only test VMs. The main files in this folder are listed below:
   
   - `ansible.cfg`: Ansible configuration file
   - `hosts`: Ansible inventory file with test VMs
   - `playbook-*`: playbooks are `lightweight` and contain a list of roles to be executed for a `purpose`
   - For more information see **README** files in [ansible-test/README.md](ansible-test/README.md)

2. The **ansible-prod** folder has the below content:
   
   - `ansible.cfg`: Ansible configuration file
   - `hosts`: Ansible inventory file with prod VMs
   - `playbook-*`: playbooks are `lightweight` and contain a list of roles to be executed for a `purpose`
   - For more information see **README** files in [ansible-prod/README.md](ansible-prod/README.md) 

3. The **ansible** folder that contains the **roles** folder. The **roles** folder has all ansible roles that can be used by playbooks placed in either **ansible-test** and/or **ansible-prod** folders: 

   - `roles`: Ansible roles contain a list of tasks to be executed in the target server. The roles are named by what they do. In example: **common-install-nginx** is a role that will install nginx package and the prefix `common` means it can be used by different playbooks.  The name of the folder is the name of the role and each role folder has to comply with required folder structure for ansible roles. See ansible [roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html) documentation for more details.

4. The **loca_dev** folder is optional to be used for "local development" as its name suggests. This folder has the below content:
   - `ansible.cfg`: Ansible configuration file
   - `Vagrantfile`: Vagrant configuration file
   - `playbook-test-roles.yml`: Ansible playbook for testing ansible roles in local Vagrant development environment
   - For more information see **README** files in [local_dev/README.md](local_dev/README.md) 

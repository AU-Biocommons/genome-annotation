# genome-annotation
Australian Biocommons Genome Annotation (Apollo).  

# Ansible

[Ansible](https://www.ansible.com/) is an automation tool for defining the target state of a host VM. Tasks to be run are specified using YAML.
1. Tasks are the atomic changes made to a host VM. 
2. Tasks are grouped into [roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html).
3. Roles can be used by [playbooks](https://docs.ansible.com/ansible/latest/user_guide/playbooks.html) to make the steps for each system easy to understand and define.

# Structure of the genome-annotation repo:
The structure of this repo is as below: 

1. ansible-test
   
   - `ansible.cfg`: Ansible configuration file
   - `hosts`: Ansible inventory file
   - `playbook-*`: playbooks are `lightweight` and contain a list of roles to be executed for a `purpose`
   - For more information see **README** files in `ansible-test/README.md`

2. ansible-prod
   
   - `ansible.cfg`: Ansible configuration file
   - `hosts`: Ansible inventory file
   - `playbook-*`: playbooks are `lightweight` and contain a list of roles to be executed for a `purpose`
   - For more information see **README** files in `ansible-prod/README.md` 

3. ansible/roles

   - `roles`: Ansible roles contain various tasks. The roles are named by what they do and how they should be used. The name of the folder is the name of the role and each role folder has to comply with required folder structure for ansible roles. See ansible [roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html) documentation for more details. 

   

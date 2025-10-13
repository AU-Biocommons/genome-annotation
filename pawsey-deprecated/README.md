# Genome Annotation
Australian Biocommons Genome Annotation (Apollo). The purpose of this repo is to **`Automate`** the installation of all required software and its dependencies in an **`Apollo VM`** using **`Ansible`**.  

# Ansible

[Ansible](https://www.ansible.com/) is an automation tool for defining the target state of a host VM. Tasks to be run are specified using YAML.
1. Tasks are the atomic changes made to a host VM. 
2. Tasks are grouped into [roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html).
3. Roles can be used by [playbooks](https://docs.ansible.com/ansible/latest/user_guide/playbooks.html) to make the steps for each system easy to understand and define.

# Folder Structure of the Genome Annotation Repo
The structure of this repo is as below: 

1. The **playbooks** folder inside the **ansible** folder. The **playbooks** folder has the below content:
   
   - `ansible.cfg`: Ansible configuration file
   - `hosts`: Ansible inventory file with **`ALL`** VMs, meaning prod VMs and test VMs
   - `playbook-*`: playbooks are `lightweight` and contain a list of roles to be executed for a `purpose`
   - For more information see **`README`** files in [ansible/playbooks/README.md](ansible/playbooks/README.md) 

2. The **roles** folder inside the **ansible** folder. The **roles** folder has all ansible roles that can be used by playbooks placed in  **playbooks** folder: 

   - `Roles`: Ansible Roles contain a list of tasks to be executed in the target server. The roles are named by what they do. In example: **common-install-nginx** is a role that will install nginx package and the prefix `common` means it can be used by different playbooks.  The name of the folder is the name of the role and each role folder has to comply with required folder structure for ansible roles. See [Ansible Roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html) documentation for more details.

3. The **local_dev** folder is optional to be used for "local development" as its name suggests. This folder has the below content:
   - `ansible.cfg`: Ansible configuration file
   - `Vagrantfile`: Vagrant configuration file
   - `playbook-test-roles.yml`: Ansible playbook for testing ansible roles in local Vagrant development environment
   - For more information see **`README`** files in [local_dev/README.md](local_dev/README.md) 

# How to Create/Modify Ansible Roles
For more information see **`README`** file in [ansible/README.md](ansible/README.md)

# What is an Apollo VM
An Apollo VM will run an [Apollo Web App](https://genomearchitect.readthedocs.io/en/latest/Setup.html) software and all its dependencies on Ubuntu OS. In summary the dependencies and software installed in an Apollo VM are as below:
1. nginx
2. tomcat
3. postgres
4. openjdk
5. Apollo Web App
6. Monitoring tools
7. Among Others

For more details refer to old manual instructions [Apollo Deployment Document](https://qcif.sharepoint.com/:w:/r/sites/3.Services/_layouts/15/Doc.aspx?sourcedoc=%7B0616808E-B7D0-4AAF-BE19-77A293661CD1%7D&file=Deploying%20a%20Production%20Web%20Apollo%20Instance.docx&action=default&mobileredirect=true). Note that this document is only for reference and to give a better understanding of all that is required to have an Apollo VM up and running as currently the Ansible Playbooks will automate the software installation process.

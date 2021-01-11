# genome-annotation - this folder contains all ansible roles
We define the state of all target servers with Ansible. This folder contains Ansible Roles that are used by the different playbooks in folders **`ansible-test`** and **`ansible-prod`**:

1. If you have reached this file it's assumed you have read the main [README](../README.md) file, if you haven't please read it first and then comeback here
2. To create a new role simply create a folder with the role name inside **`ansible`** folder
3. Create a folder named **`tasks`** inside the role folder 
4. Create a file named **`main.yml`** inside the **`tasks`** folder
5. Note that roles can have more folders and files but the above is the bare minimum that is needed as any other folders and files are optional
6. If you are not familiar with Yaml it's recommended to do a tutorial about Yaml language and also then look into [Ansible Roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html) documentation for more details
7. Once your role is ready to be added to an existing playbook or create a new playbook that will use this role as required
8. If a new playbook is created or if modifying an existing playbook then push the changes first to **`ansible-test`** folder and test it in the Ansible Sandpit. For more information about how to run ansible playbooks see **`README`** file in [ansible-test/README.md](../ansible-test/README.md) folder
9. Once the playbook has been tested from **`ansible-test`** folder and test results are satisfactory then push your changes to **`ansible-prod`** folder. For more information about how to run ansible playbooks see **`README`** file in [ansible-prod/README.md](../ansible-prod/README.md) folder
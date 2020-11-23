# genome-annotation - this folder defines the state of servers 
We define the state of the live and/or test servers with Ansible

We run Ansible in two different locations 
1. local_dev (Vagrant)
2. ansible (Live or test servers)

See local_dev folder for more details. Please be **Very Careful!** when
running any of the ansible playbooks in the ansible folder as these may
impact live (production) apollo VMs

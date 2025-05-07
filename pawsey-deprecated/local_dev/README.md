# genome-annotation - this folder is for local development
We define the state of the local development server with Ansible
and Vagrant. In order to test Ansible in the local development 
server follow the below instructions:

1. Install Vagrant in your local machine
2. Pull latest files in **local_dev** folder from git repo 
3. Download your desired image using your preferred provider: hyper-v or virtual box.
4. Modify `Vagrantfile` to be consistent will your local environment. In example: make sure folder paths are correct, and/or modify all that is relevant.
5. Perform the below commands as required
    
    ```
    $ cd local_dev
    
    $ vagrant up --provider=your_provider local_server_name
    
    $ vagrant rsync local_server_name
    
    $ vagrant provision local_server_name --provision-with=your_run_config
    ```
 
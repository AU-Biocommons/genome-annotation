# genome-annotation - this folder is for local development
We define the state of the local development server with Ansible
and Vagrant. In order to test Ansible in the local development 
server follow the below instructions

1. Install Vagrant in your local machine
2. Download your desired image using your preferred provider
3. Perform the below commands as required
    
    ```
    $ cd local_dev
    
    $ vagrant up --provider=your_provider local_server_name
    
    $ vagrant rsync local_server_name
    
    $ vagrant provision apollo --provision-with=your_run_config
    ```
 
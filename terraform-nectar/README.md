# Terraform (Nectar)

Infrastructure-as-code for provisioning Nectar OpenStack resources that host the Australian Apollo Service.

- Provider: OpenStack (Nectar)
- State: keep out of Git (remote backend recommended)
- Configuration: non-secret variables are versioned; never commit credentials (including the `apollo-openrc.sh` file).

## Prerequisites

1) Terraform installed from OS distro or inside a virtual environment.
2) OpenStack credentials exported to shell with `source apollo-openrc.sh`, using the RC file obtained from Nectar for the Apollo tenancy. Requires entering your Nectar API password.
3) Network prerequisite (manual):
- Internal network `apollo-internal-network` with subnet `192.168.0.0/24` must exist before applying these configs.
- Public networking and floating IPs should be available in the project.

## Layout and naming scheme

Terraform files and their intent:

- `apollo-varsanddata.tf`
Variables and data sources for creating Apollo and related hosts. This includes commonly used variables such as `apollo_security_groups`.

- `servers-nectar.tf`
Core, long-lived infrastructure servers. Lifecycle uses `prevent_destroy` to avoid accidental deletion.

- `internal-apollos-nectar.tf`
`tfi_` (terraform internal): internal Apollo/JBrowse sandpits and related VMs.

- `temporary-apollos-nectar.tf`
`tft_` (terraform temporary): short-lived teaching and test Apollo instances that may be recreated frequently.

- `client-apollos-nectar.tf`
`tfc_` (terraform client): client-facing Apollo/JBrowse instances.

- `secgroups-nectar.tf`
Security group definitions. These are applied to VMs directly (in `servers-nectar.tf`) or via variables (e.g. `apollo_security_groups` in `apollo-varsanddata.tf`).

- `providers.tf`
Terraform OpenStack provider configuration.

- `large-volumes-nectar_not_managed.txt`
Notes on large volumes that are intentionally not managed by Terraform.

- `test-vm-definition.txt`
Template for testing VM definitions. Duplicate and rename to `.tf` to use during experiments.

Prefix notes:
- `tfs_`: infrastructure-only, protected by `prevent_destroy`
- `tfi_`: internal sandpit resources
- `tft_`: temporary, frequently recreated resources
- `tfc_`: client resources

## Typical workflow

1) Change into directory containing these definitions and terraform state files.
2) Source the Nectar openstack environment: `source apollo-openrc.sh`
3) Edit the appropriate terraform definition file to create a new VM:
- `servers-nectar.tf` to create a new server VM;
- `apollo-varsanddata.tf` to create a new apollo VM by adding an entry to `client_apollo_numbers` for example.
4) Test changes with `terraform plan`.
5) Proceed to create the new VM with `terraform apply`. This will result in a VM named `tf<TYPE>_<HOST_NAME>_<YYYYMMDD>`.
6) Obtain details of VM created today (easiest and most general approach), with `openstack server list | grep YYYYMMDD`. Record internal `192.168.0.0/24` subnet IP address and external (floating IP) address. Other useful details can be obtained with `openstack server show <VM-NAME>`

**Post creation**:
7) Add A Record and CNAME Entries for New VM to Cloudflare DNS.
- An __A record__ for `apollo-XXX.genome.edu.au` (where XXX=001-999) with the floating IP address found above;
- A __CNAME__ defined as the custom host name (for example the lab or organism name of interest) that points to the A record just defined,
-  Note that `Proxy status` should be set to `DNS only`
8) Record the apollo number (if an apollo instance), custom hostname and local IP address. These will all be needed by the ansible playbooks for building the host.
9) Commit changes to terraform definitions (**NOT** terraform state) to github repo.

**Next Steps**:
10) Login to new VM using the ssh keypair defined by `key_pair` (in the VM definition) as the default user defined by the OS image (e.g. `ubuntu`).
11) Ensure the new A record hostnames appear in the Ansible inventory (`ansible/playbooks/hosts`). In the case of Apollo clients the hostname will be of the form `apollo-XXX.genome.edu.au`. An internally resolvable (via /etc/hosts) entry can also be provided, with for example `ansible_host=apollo-XXX`.
12) Proceed with configuration using Ansible playbooks (see `ansible/playbooks/README.md`).

## State and secrets
- Do not commit state files. Use a remote backend or keep local state outside Git.  
- Do not commit credentials or tokens. Provide them via environment variables (`apollo-openrc.sh`) or your chosen secrets manager.
- Non-secret variables (including security groups and VM definitions) are versioned in Git by design.


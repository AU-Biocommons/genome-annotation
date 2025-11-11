# Terraform (Nectar)

Infrastructure-as-code for provisioning Nectar OpenStack resources that host the Australian Apollo Service.

- Provider: OpenStack (Nectar)
- State: keep out of Git (remote backend recommended)
- Configuration: non-secret variables are versioned; never commit credentials (including the `apollo-openrc.sh` file).

## Prerequisites

1) Terraform installed from OS distro or inside a virtual environment.
2) OpenStack credentials exported to shell with `source apollo-openrc.sh`, using the RC file obtained from Nectar for the Apollo tenancy. Requires entering your Nectar API password.
3) Network prerequisite (manual) prior to applying Terraform configurations:
- Router connected to external network (`ardc-syd`) needs to be created (or be pre-existing).
- Internal network `apollo-internal-network` connected to router with subnet `192.168.0.0/24` must be created.
- Public networking and floating IPs should be available in the project.

## Layout and naming scheme

Terraform files and their intent:

- `apollo-varsanddata.tf`
Variables and data sources for creating (or deleting) Apollo instances and managing their flavours and security groups. In general, __this should be the only file requiring updates__.

- `servers-nectar.tf`
Core, long-lived infrastructure servers, each defined independantly as per requirements. This file is stable and rarely changed. Lifecycle uses `prevent_destroy` to avoid accidental deletion. **Do not modify** without a justified operational need (such as adding a new server). Modifications to existing resources **should only** be made for planned lifecycle events (replacement, major upgrades) and requires rationale, impact assessment, peer review, and rollback steps.

- `internal-apollos-nectar.tf`
`tfi_` (terraform internal): Definition for internal Apollo or JBrowse instances, such as the Apollo build VM and development sandpits. This file is stable and rarely changed. Modifications **should not** be required, the exception being for adding additional volume storage when required (as currently done for apollo-011).

- `temporary-apollos-nectar.tf`
`tft_` (terraform temporary): Definition for short-lived teaching and test Apollo instances that may be recreated frequently. This file is stable and rarely changed. Modifications **should not** be required.

- `client-apollos-nectar.tf`
`tfc_` (terraform client): Definition for client-facing Apollo/JBrowse instances. This file is stable and rarely changed. Modifications **should not** be required.

- `secgroups-nectar.tf`
Security group definitions. These are applied to VMs directly (in `servers-nectar.tf`) or via variables (e.g. `apollo_security_groups` in `apollo-varsanddata.tf`). This file is stable and rarely changed. **Do not modify** without a justified operational need (such as adding a new security group). Modifications to existing resources **should not be made without justified operational need and change plan!**

- `providers.tf`
Terraform OpenStack provider configuration. This file is stable and should not require changes. **Do not modify without a justified operational need and change plan!**

- `large-volumes-nectar_not_managed.txt`
Notes on large volumes that are intentionally not managed by Terraform.

- `test-vm-definition.txt`
Template for testing VM definitions. Duplicate and rename to `.tf` to use during experiments.

**Prefix notes:**
- `tfs_`: infrastructure-only, protected by `prevent_destroy`
- `tfi_`: internal sandpit resources
- `tft_`: temporary, frequently recreated resources
- `tfc_`: client resources

## Restart procedure

This sequence minimizes false alerts, avoids stale NFS mounts, and keeps users informed via the offline portal.

### Preparation

- Prepare the **offline portal**:
  - Update the outage page on `apollo-portal-offline` with start/end time and contact info.
  - Verify TLS on `apollo-portal-offline.genome.edu.au` (renew if needed).

---

### Shutdown order

1) **Monitoring**
   - Stop `apollo-monitor` first to avoid alert storms.

2) **Public portal cutover**
   - On `apollo-portal-offline`, publish the outage page.
   - Switch DNS: point `apollo-portal.genome.edu.au` **CNAME** to `apollo-portal-offline.genome.edu.au`.
   - Verify the offline portal is serving over HTTPS.
   - Shut down the main `apollo-portal` VM.

3) **Application tier**
   - Shut down all **Apollo** and **JBrowse** hosts (and any **test/sandpit** VMs).

4) **NFS**
   - After all clients are down, shut down `apollo-user-nfs`. This _(Prevents stale NFS handles.)_

5) **Deployment/backup**
   - Shut down `apollo-backup` last.

> Notes
> - If any host refuses to stop cleanly, use the cloud console to issue a shutdown.

---

### Startup order

1) **Deployment/backup**
   - Start `apollo-backup`. Verify SSH and local services (e.g., crond, backup volume mounted).

2) **NFS**
   - Start `apollo-user-nfs`. Confirm exports are active:
     ```bash
     showmount -e localhost
     exportfs -v
     ```

3) **Application tier**
   - Start all **Apollo** and **JBrowse** hosts (and test VMs).
   - On a representative Apollo host, confirm mounts and services:
     ```bash
     mount | grep nfs
     systemctl status nginx tomcat9
     ```

4) **Public portal**
   - Start `apollo-portal`.
   - Switch DNS: point `apollo-portal.genome.edu.au` **CNAME** back to the main portal
     `apollo-portal-main.genome.edu.au`.
   - After DNS propagation, verify website is available and TLS (renew if needed).

5) **Monitoring**
   - Start `apollo-monitor`. Confirm Prometheus targets are up and Grafana is reachable.

---

### Post-restart checks

- **DNS**: `dig +short CNAME apollo-portal.genome.edu.au` shows the main portal target; HTTPS ok.
- **NFS**: clients have mounts; `dmesg` shows no NFS stale file handle errors.
- **Apollo**: key instances respond (200/302), Tomcat healthy, DB connections OK.
- **Backups**: `apollo-backup` has the backup volume mounted; next cron window will run normally.
- **Monitoring**: Prometheus targets green; Grafana dashboards load; no persistent critical alerts.

## Typical workflow for apollo VM creation

1. Change into directory containing these definitions and terraform state files.
2. Source the Nectar openstack environment: `source apollo-openrc.sh`
3. Edit `apollo-varsanddata.tf` to create a new Apollo VM or delete an existing Apollo by
   adding or removing an entry in one of
    -  `temporary_apollo_numbers` for a `tft_apollo_XXX` VM.
    -  `internal_apollo_numbers` for a `tfi_apollo_XXX_YYYYMMDD` VM.
    -  `client_apollo_numbers` for a `tfc_apollo_XXX_YYYYMMDD` VM.

    If required, customise the VM flavor (for more or less resources) by adding a matching entry to `apollo_flavors`.

4. Test changes with `terraform plan`.
5. Proceed to create the new VM with `terraform apply`. This will result in a VM named `tf<T>_apollo_<XXX>_<YYYYMMDD>`, where `<T>` is one of `t`, `i` or `c`; `<XXX>` is 001-999; and `<YYYYMMDD>` is today's date.
6. Obtain details of VM created today (easiest and most general approach), with `openstack server list | grep <YYYYMMDD>`. Record internal `192.168.0.0/24` subnet IP address and external (floating IP) address. Other useful details can be obtained with `openstack server show <VM-NAME>`

**Post creation**:

7. Add A Record and CNAME Entries for new VM to Cloudflare DNS.
    - An __A record__ for `apollo-XXX.genome.edu.au` (where XXX=001-999) with the floating IP address found above;
    - A __CNAME__ defined as the custom host name (for example the lab or organism name of interest) that points to the A record just defined,
    -  Note that `Proxy status` should be set to `DNS only`
8. Record the apollo number, custom hostname and local IP address. These will all be needed by the ansible playbooks for building the host.
9. Commit changes to terraform definitions (**NOT** terraform state) to github repo.

**Next Steps**:

10. Login to new VM using the apollo ssh keypair (defined by `key_pair` in the VM definition file `client-apollos-nectar.tf`) as the default user defined by the OS image (e.g. `ubuntu`).
11. Ensure the new A record hostname (`apollo-XXX.genome.edu.au`) appears in the Ansible inventory (`ansible/playbooks/hosts`). An internally resolvable (via `/etc/hosts`) entry can also be provided here, with for example `ansible_host=apollo-XXX`.
12. Proceed with host configuration using Ansible playbooks (see `ansible/playbooks/README.md`).

## State and secrets
- Do not commit state files. Use a remote backend or keep local state outside Git.  
- Do not commit credentials or tokens. Provide them via environment variables (`apollo-openrc.sh`) or your chosen secrets manager.
- Non-secret variables (including security groups and VM definitions) are versioned in Git by design.


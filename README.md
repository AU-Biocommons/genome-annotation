# Australian BioCommons Genome Annotation (Apollo Service) Infrastructure

This repository defines and automates deployment of the **Australian Apollo Service** hosted on the **Nectar Research Cloud**.
Infrastructure is provisioned with **Terraform** and configured with **Ansible**.

## Overview

This repository supports production and development environments for the Apollo Service, including the Apollo Portal, client Apollo and JBrowse instances, shared storage, monitoring, backups, and sandpit systems used for testing.

## Repository structure

| Directory | Description |
|---|---|
| **ansible/** | Ansible content for configuring all VMs. See `ansible/playbooks/README.md`. |
| **ansible/playbooks/** | Playbooks that deploy/configure portal, backup, NFS, monitoring, JBrowse, and client instances. Inventory at `ansible/playbooks/hosts` (FQDNs and internal shortnames only). |
| **ansible/roles/** | Supporting roles used by the playbooks. |
| **ansible-galaxy/** | External roles supplied by [Ansible Galaxy](https://galaxy.ansible.com/). |
| **backup_scripts/** | Backup and usage scripts, backup scheduling example (crontab).  |
| **terraform-nectar/** | Terraform configuration for VMs, networks, and related infrastructure on Nectar. Security groups in `terraform-nectar/secgroups-nectar.tf` and applied via variables (e.g. `apollo_security_groups` in `terraform-nectar/apollo-varsanddata.tf`). |
| **other/** | Miscellaneous supporting files and examples. |
| **pawsey-deprecated/** | Archived materials from the retired Pawsey deployment (history only). |

## Getting started

- **Ansible:** see `ansible/playbooks/README.md` for playbook usage and operational notes.  
- **Terraform:** see `terraform-nectar/README.md` for provisioning workflows and environment setup.  
- **Backups:** see `backup_scripts/README.md`.

## Security and privacy

Do **not** commit credentials, tokens, or secrets in the open. Provide secrets via environment variables, a local gitignored `terraform.tfvars`, or Ansible Vault (see for example `ansible/playbooks/group_vars/newapollovms/vault`).
Terraform state files are kept out of version control (use a remote backend or store locally outside Git).
  
## License / Contact

This repository is maintained by the Australian Apollo Service team. For questions or access requests, contact the Apollo service administrators via the [apollo-portal](https://apollo-portal.genome.edu.au).

## Credits

[Contributors](https://github.com/AU-Biocommons/genome-annotation/graphs/contributors)


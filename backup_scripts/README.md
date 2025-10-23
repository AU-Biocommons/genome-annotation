# Backup Scripts

Scripts and schedules for backing up the Australian Apollo Service.

- Primary host: `apollo-backup` (deployment + backup server)
- Targets: Apollo Portal, client Apollo2 instances, JBrowse portal, infrastructure and other selected VMs
- Data paths: VM files via rsync/SSH; PostgreSQL via network `pg_dump` on TCP 5432
- Storage: local Ceph volume on `apollo-backup` + offsite copy to Nectar Object Storage (Swift)

> Secrets (Swift credentials, DB passwords, etc.) are **not** stored here. Provide via environment, Ansible Vault, or the deployment host’s protected config.

---

## Contents

- `crontab.txt` - template cron schedule to (manually) install on `apollo-backup` (with modifications as required).
- `backup-*.sh` - backup scripts invoked by cron for hosts or host groups. These utilise `rsync`, `pg_dump` and `swift`.
- `swift-backup-*` - scripts called by backup scripts that provide the credentials, upload or deletion information and other details regarding backups to object store with swift.
- `backupToSwift.sh`, `deleteOldSwiftObjects.sh`, `listSwift.sh` - these are called by the `swift-backup` scripts and perform the actual swift operations.
- `Description of Genome Annotation (Apollo) Project Backup Strategy.odt` - original documentation on backup strategy
- `get_apollo_users_organisms.sh` - queries apollo2 instances for usage information on users and organisms.
- `gen_usage_report.sh` - calls `get_apollo_users_organisms.sh` to provide the raw usage data and collates information for reporting.
- `README.md` - this file

---

## What gets backed up (high level)

- **PostgreSQL databases (Apollo2 + portal):**
  - Full database backups using `pg_dump` from **`apollo-backup`** to each target over TCP 5432 (no SSH tunneling).
- **File data:**
  - Apollo/JBrowse and other VMs configuration via `rsync` over SSH from targets to `apollo-backup`.
  - Apollo/JBrowse datasets can be read from NFS exports where appropriate (adjust includes/excludes to avoid duplicating large read-only data if not needed).


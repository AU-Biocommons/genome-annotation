# Backup Scripts

Scripts and schedules for backing up the **Australian Apollo Service**.

- **Primary host:** `apollo-backup` (deployment + backup server)
- **Targets:** Apollo Portal, client Apollo2 instances, JBrowse portal, infrastructure (monitor, NFS) and other selected VMs
- **Data paths:** VM files via rsync/SSH; PostgreSQL via network `pg_dump` on TCP 5432 (initiated from `apollo-backup`)
- **Storage**: local Ceph volume on `apollo-backup` + offsite copy to Nectar Object Storage (Swift)

> Secrets (Swift credentials, DB passwords, etc.) are **not** stored here. Provide via environment, Ansible Vault, or protected config on the deployment host.

---

## Contents

- `crontab.txt` - template cron schedule to (manually) install on `apollo-backup` (with modifications as required).
- `backup-*.sh` - backup scripts invoked by cron for hosts or host groups. These utilise `rsync`, `pg_dump` and `swift`.
- `swift-backup-*` - helper scripts (creds/selection/retention) for backups to object storage via Swift.
- `backupToSwift.sh`, `deleteOldSwiftObjects.sh`, `listSwift.sh` - shared Swift helpers called by the `swift-backup` scripts and perform the actual swift operations.
- `Description of Genome Annotation (Apollo) Project Backup Strategy.odt` - original documentation on backup strategy
- `get_apollo_users_organisms.sh` - queries apollo2 instances for usage information on users and organisms.
- `gen_usage_report.sh` - calls `get_apollo_users_organisms.sh` to provide the raw usage data and collates information for reporting.
- `README.md` - this file

---

## Local backup layout, logs, retention

- Base volume: `BACKUP_VOL="/mnt/backup00/nectar"`
- Per-target directory: `BACKUP_DIR="${BACKUP_VOL}/${NAME}"`
- Logs: `LOGFILE_DIR="${BACKUP_VOL}/logs"`, one logfile per script/target
- Archives: `ARCHIVE_DIR="${BACKUP_DIR}_archive"`

Retention (by script):
- SQL dumps: usually **30 days** (`find ... -name "*.sql" -mtime +30 -delete`)
- Archives: **13–30 days** depending on host (see per-host sections below)

---

## Scheduling (cron)

The canonical schedule is in `crontab.txt

---

## What gets backed up (high level)

- **PostgreSQL databases (Apollo2 + portal):**
  - Full database backups using `pg_dump` from **`apollo-backup`** to each target over TCP 5432 (no SSH tunneling).
- **File data:**
  - Apollo/JBrowse and other VMs configuration via `rsync` over SSH from targets to `apollo-backup`.
  - Apollo/JBrowse datasets can be read from NFS exports where appropriate (adjust includes/excludes to avoid duplicating large read-only data if not needed).

---

## Apollo backups (client instances)

### Design notes (important)
- **No NFS “apollo_data” bulk copy**: client Apollo2 VMs do **not** back up large NFS-hosted datasets (`apollo_data`/`sourcedata`) nightly. These are handled **case-by-case** when archiving an Apollo.
- **Nightly backup includes**:
  - **Home directories** (minus caches and build detritus)
  - **Web & config**: `/var/www`, `/etc/nginx`
  - **PostgreSQL**: `pg_dump` of `apollo-production` (per client) from `apollo-backup`

### Batch backup of all clients — `backup-apollos.sh`
- **NAME:** `apollo-XXX` where `XXX` is the apollo number 001 - 999
- **Schedule:** daily
- **Input list:** `/home/backup_user/list_of_apollo_instances.txt` (one remote host per line)
- **Per-host actions:**
  - Ensure `BACKUP_DIR` and `ARCHIVE_DIR`
  - `rsync`:
    - `/home` -> `BACKUP_DIR` (excludes `home/data`, `*/.cache`, `*/.local`)
    - `/var/www` -> `BACKUP_DIR`
    - `/etc/nginx` -> `BACKUP_DIR`
  - `pg_dump apollo-production -h <remote> -U backup_user > BACKUP_DIR/<remote>_<YYYYMMDD>.sql`
  - Prune: archives older than **13 days**; SQL dumps older than **30 days**
  - **Weekly archive**: modulo schedule on instance number vs day-of-week; archives the **entire `BACKUP_DIR`**

**Add/remove a client Apollo:**
1. Edit `/home/backup_user/list_of_apollo_instances.txt`
2. Ensure `backup_user` SSH + DB role on target
3. Next cron window picks it up

---

## Apollo build server backups

### `backup-build-apollo.sh` (e.g. build host `apollo-011`)
- **NAME:** `apollo-sandpit`
- **Schedule:** daily
- **Backs up:**
  - `/opt/apollo-build` (build artifacts)
  - `/home` (common excludes)
  - `/var/www`, `/etc/nginx`
  - `pg_dump apollo-production -h <remote>`
- **Weekly archive:** **Monday**
- **Retention:** archives ~13 days; SQL 30 days

---

## Apollo-portal backup

### `backup-django-portal.sh` (host: `apollo-portal`)
- **NAME:** `django-portal`
- **Schedule:** daily
- **Backs up:**
  - `/home/ubuntu` (excluding git/venv/site tree), plus selective user homes
  - **Media**: `${WEBSITE_DIR}/media` where `WEBSITE_DIR=/srv/sites/apollo_portal/app/apollo_portal`
  - `/etc/nginx`
  - `pg_dump apollo_portal -h apollo-portal -U backup_user`
- **Weekly archive:** **Tuesday**
- **Retention:** archives **30 days**; SQL **30 days**

> Most portal code is in Git; focus is on media and config.

---

## JBrowse portal backup

### `backup-jbrowse-portal.sh` (host: `apollo-user-jbrowse`)
- **NAME:** `jbrowse-portal`
- **Schedule:** daily
- **Backs up:**
  - **Per-mount JBrowse conf**: iterate `/mnt/jbrowse-0*` and `rsync` each `${mount}/conf` to `${BACKUP_DIR}/conf/<mountname>`
  - `/home` (excludes caches/build artefacts)
  - `/var/www`, `/etc/nginx`
- **Weekly archive:** **Tuesday**
- **Retention:** archives **13 days**

> Builds under `/opt/jbrowse/build` are intentionally not backed up (duplicated in `/var/www` minus `.git`).

---

## Monitoring server backup

### `backup-monitor-server.sh` (host: `apollo-monitor`)
- **NAME:** `apollo-monitor`
- **Schedule:** daily
- **Backs up:** `/home` (excludes caches), `/etc`
- **Weekly archive:** **Thursday**
- **Retention:** archives **30 days**

---

## NFS server backup

### `backup-user-nfs.sh` (host: `apollo-user-nfs`)
- **NAME:** `user-nfs`
- **Schedule:** daily
- **Backs up:** `/etc`, selected user homes (e.g. `/home/ubuntu`)
- **Weekly archive:** **Wednesday**
- **Retention:** archives **30 days**

> This does **not** pull bulk NFS exports (user/project data). Large datasets are handled separately.

---

## Deployment/backup host self-backup

### `backup-combo-deploy-server.sh` (host: `apollo-backup`)
- **NAME:** `apollo-backup`
- **Schedule:** daily
- **Backs up (local `rsync`):** `/home` (excludes caches), `/etc`
- **Weekly archive:** **Monday** (uses `sudo tar` to preserve ownership/permissions)
- **Retention:** archives **30 days**

---

## Offsite copies (Swift)

Nightly Swift jobs (see `crontab.txt`):
- `swift-backup-delete-old-SQL.sh`
- `swift-backup-delete-old-data.sh`
- `swift-backup-apollo-SQL.sh`
- `swift-backup-apollo-data.sh`

Helpers:
- `swift-backup-*` (credential/selection/retention)
- `backupToSwift.sh`, `deleteOldSwiftObjects.sh`, `listSwift.sh`

> Configure Swift credentials out-of-band. Ensure container names, retention, and include/exclude rules align with cost and recovery objectives.

---

## Verification & monitoring

- **Logs:** `${BACKUP_VOL}/logs/*.log`
- **Quick checks:**
```
# SQL dumps generated in the last 24h
find /mnt/backup00/nectar -type f -name "*.sql" -mtime -1 | wc -l

# Validate a dump structure (example)
pg_restore --list /mnt/backup00/nectar/django-portal/apollo-portal_YYYYMMDD.sql > /dev/null

```

---

## Adding a new Apollo client to nightly backups

1. Ensure `backup_user` SSH + DB permissions on the VM.
2. Append the hostname to `/home/backup_user/list_of_apollo_instances.txt` (this is done by `playbook-apollo-add-to-backup-server.yml` as run from `build-newapollo.sh`).
3. Confirm hostname is in `/etc/hosts` and TCP 5432 reachability from `apollo-backup`.
4. The next scheduled apollo backup will include it automatically.

---

## Restoring from Backups

In general Apollo restores are done to a cleanly provisioned VM by copying the latest database backup to `/opt/apollo_files/restore/` and running the `build-newapollo.sh` script (see `../ansible/playbooks/README.md`) which restores the database with `playbook-restore-apollo-db.yml`.

After the build and restore of the database has completed, then backed up files are rsynced into place (see below).

### PostgreSQL restore (manual process)
The manual process for restoring a postgres database is to create the empty database and then restore from backup:
```
createdb <restore_db>
pg_restore --dbname=<restore_db> --clean --if-exists /path/to/<host>_<DATE>.sql
```

### File restore (manual process)
The manual process for restoring backups of configs and data is:
```
# Restore directory to temp location on remote host
rsync -avz /mnt/backup00/nectar/apollo-XXX/path/to/data/ backup_user@apollo-XXX:/tmp/
```
Login to the host as the `ubuntu` user, ensure the files have the correct ownership and then move into place. For example, restoring the config files in an apollo user home directory:
```
sudo chown -R apollo_user:apollo_user /tmp/apollo_user
for f in .ssh/authorized_keys .bash_history .bashrc .conda .condarc .config .vim .viminfo; do
    sudo mv /tmp/apollo_user/$f /home/apollo_user/$f
done
```

In the case of user data, this is kept on the NFS server, not local disk, so will be immediately available on a restored apollo.

---

## Related docs

- **Terraform provisioning** - `../terraform-nectar/README.md`
- **Ansible operations** - `../ansible/playbooks/README.md`


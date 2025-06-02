#!/bin/bash

FS='' read -d '' -r usage_str <<EOF
Usage: $(basename $0)  [ -h ] [ -d ] [ -p admin_password ] inventory_file
Where:
    -h provides this handy help
    -d specifies dry-run (don't build apollo) - runs ansible with --check
    -p admin_password = provide secret password for the apollo admin user (ops@qfab.org)
                        (otherwise default password from ansible vault will be used)
    inventory_file = ansible inventory file for building apollo instance
EOF

admin_password=""
check_str=""
target_environment="prod"

while getopts hdp: opt; do
    case "$opt" in
        h) # help
            echo >&2 "$usage_str"
            exit 0
            ;;
        d) # dry run using ansible --check
	    check_str="--check"
            ;;
        p) # admin password for apollo
            admin_password="$OPTARG"
	    ;;
        \?) # unknown flag
            echo >&2 "$usage_str"
            exit 1
            ;;
    esac
done

# get rid of option params
shift $((OPTIND-1))

# the trailing parameter is the inventory file
if [ $# -eq 1 ]; then
    inventory_file=$1
    if [ ! -f ${inventory_file} ]; then
        echo >&2 "Error: inventory file \"${inventory_file}\" does not exist.. exiting!"
	exit 1
    fi
    shift
else
    echo >&2 "$usage_str"
    exit 1
fi

# determine whether we are deploying a production apollo or test apollo (apollo-999)
# grep args: -q be quiet; -F pattern is a plain string
# grep returns 0 if a line is selected, 1 if no lines were selected, and 2 if an error occurred
grep -qF target_environment=prod $inventory_file || target_environment="test"

echo "Please ensure the ansible vault password has been exported to the environment, i.e.:"
echo "  $  export VAULT_PASSWORD=\"<SECRET_VAULT_PASSWORD>\""
read -p "Press enter to continue (Ctrl-C to abort)"
echo ""

echo "propogate local IP address of apollo VM to /etc/hosts on servers"
echo "ansible-playbook playbook-set-etc-hosts-ip.yml --inventory-file $inventory_file --limit changeipvms $check_str"
ansible-playbook playbook-set-etc-hosts-ip.yml --inventory-file $inventory_file --limit changeipvms $check_str
if [ $? -ne 0 ] && [ -z "$check_str" ]; then
  echo >&2 "Error running playbook-set-etc-hosts-ip.yml... aborting!"
  exit 1
fi
echo
echo "Done."
echo

echo "set up NFS export for apollo VM"
echo "ansible-playbook playbook-apollo-ubuntu-nfs-server.yml --inventory-file $inventory_file --limit nfsservervms $check_str"
ansible-playbook playbook-apollo-ubuntu-nfs-server.yml --inventory-file $inventory_file --limit nfsservervms $check_str
if [ $? -ne 0 ] && [ -z "$check_str" ]; then
  echo >&2 "Error running playbook-apollo-ubuntu-nfs-server.yml... aborting!"
  exit 1
fi
echo
echo "Done."
echo 

echo "run combined playbook to build apollo"
# if no admin password provided, ansible will use default from ansible vault
if [ -z "$admin_password" ]; then
    echo "INFO: using default apollo admin password from ansible vault"
    echo "ansible-playbook playbook-apollo-ubuntu-combined.yml --inventory-file $inventory_file --limit newapollovms $check_str"
    ansible-playbook playbook-apollo-ubuntu-combined.yml --inventory-file $inventory_file --limit newapollovms $check_str
else
    echo "ansible-playbook playbook-apollo-ubuntu-combined.yml --inventory-file $inventory_file --limit newapollovms -extra-vars=\"apollo_admin_password=<SECRET>\" $check_str"
    ansible-playbook playbook-apollo-ubuntu-combined.yml --inventory-file $inventory_file --limit newapollovms --extra-vars="apollo_admin_password=$admin_password" $check_str
fi
if [ $? -ne 0 ] && [ -z "$check_str" ]; then
  echo >&2 "Error running playbook-apollo-ubuntu-combined.yml... aborting!"
  echo >&2 "Note: a common cause of this is when unattended-upgrades is running on instance"
  echo >&2 "      fix by logging into the VM and killing the unattended-upgrades process with"
  echo >&2 "          sudo kill -KILL \$(pgrep -u root -f unattended-upgrades)"
  echo >&2 "      Then re-run playbook"
  exit 1
fi
echo
echo "Done."
echo 

if [ "$target_environment" = "test" ]; then
	echo "Apollo test VM build complete! Note: test apollo not added to monitoring or backups"
	echo
	exit 0
fi

: <<'DISABLE_MONITORING_REGISTRATION'
# ---------------------------
# Skipping until monitoring is configured
echo "add apollo instance to monitoring"
echo "ansible-playbook playbook-apollo-ubuntu-monitor.yml --inventory-file $inventory_file --limit monitorservervms $check_str"
ansible-playbook playbook-apollo-ubuntu-monitor.yml --inventory-file $inventory_file --limit monitorservervms $check_str
if [ $? -ne 0 ] && [ -z "$check_str" ]; then
  echo >&2 "Error running playbook-apollo-ubuntu-monitor.yml... aborting!"
  exit 1
fi
echo
echo "Done."
echo 
# ---------------------------
DISABLE_MONITORING_REGISTRATION

: <<'DISABLE_BACKUP_REGISTRATION'
# ---------------------------
echo "add apollo instance to list of apollo's to backup"
echo "ansible-playbook playbook-apollo-add-to-backup-server.yml --inventory-file $inventory_file --limit backupservervms $check_str"
ansible-playbook playbook-apollo-add-to-backup-server.yml --inventory-file $inventory_file --limit backupservervms $check_str
if [ $? -ne 0 ] && [ -z "$check_str" ]; then
  echo >&2 "Error running playbook-apollo-add-to-backup-server.yml... aborting!"
  exit 1
fi
echo
echo "Done."
echo 
# ---------------------------
DISABLE_BACKUP_REGISTRATION

echo "Apollo build complete!"
echo


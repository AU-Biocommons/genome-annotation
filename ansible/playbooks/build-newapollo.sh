#!/bin/bash

IFS='' read -d '' -r usage_str <<EOF
Usage: $(basename $0) [ -h ] [ -d ] [ -p admin_password ] [-a apollovms_hosts_file] apollo_number custom_hostname private_ip_address
Where:
    -h provides this handy help
    -d specifies dry-run - don't build apollo or update hosts file
    -p admin_password = provide secret password for the apollo admin user (ops@qfab.org)
                        (otherwise default password from ansible vault will be used)
    -a apollovms_hosts_file = inventory file for existing apollo VMs (by default 'hosts')
        this file contains the 'apollovms' group defining all the apollo VMs
        primarily used for running system updates
        the new apollo VM will be added to this group in the hosts file
    apollo_number = 001-998 for target_environment=prod, or 999 for target_environment=test
    custom_hostname = alphanumeric string with '-' allowed within string
    private_ip_address = 192.168.X.Y
EOF

dryrunstr=""
admin_password_str=""
apollo_hosts_file="hosts"
apollo_number="000"
custom_hostname=""
ip_address=""
target_environment="prod"

while getopts hdp:a: opt; do
    case "$opt" in
        h) # help
            echo >&2 "$usage_str"
            exit 0
            ;;
        d) # dry-run - don't build apollo
            dryrun="-d"
            ;;
        p) # password for apollo admin
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

if [ $# -ne 3 ]; then
    echo >&2 "$usage_str"
    exit 1
fi

if [[ $1 =~ ^[0-9][0-9][0-9]$ ]]; then
    apollo_number=$1
fi

if [ $apollo_number = "000" ]; then
    echo >&2 "invalid apollo_number: $1"
    exit 1
elif [ $apollo_number = "999" ]; then
    target_environment="test"
fi
shift

# allow hyphen only within string
if [[ $1 =~ ^[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]$ ]] || [[ $1 =~ ^[a-zA-Z0-9] ]]; then
    custom_hostname=$1
fi
if [ -z "$custom_hostname" ]; then
    echo >&2 "invalid custom hostname: $1"
    exit 1
fi
shift


if [[ $1 =~ ^192\.168\.[0-9]+\.[0-9]+$ ]]; then
    ip_address=$1
fi
if [ -z "$ip_address" ]; then
    echo >&2 "invalid private IP address: $1"
    exit 1
fi
shift

inventory_file="buildapollo.${apollo_number}.inventory"
build-newapollo-inventory.sh $apollo_number $custom_hostname $private_ip_address
if [ $? -ne 0 ]; then
    echo >&2 "Error creating inventory file ($inventory_file) for Apollo build... aborting"
    echo >&2 "Command run was:"
    echo >&2 "    build-newapollo-inventory.sh $apollo_number $custom_hostname $private_ip_address"
    exit 1
fi

build-newapollo-runplaybooks.sh "$dryrun_str" "$admin_password_str" "$inventory_file"
if [ $? -ne 0 ]; then
    echo >&2 "Error occurred while running ansible scripts"
    echo >&2 "Fix issue and then re-run playbooks with:"
    echo >&2 "    build-newapollo-runplaybooks.sh $dryrun_str $admin_password_str $inventory_file"
    echo >&2 "Then manually add entry for apollo-$apollo_number to 'apollovms' section in the file ${apollo_hosts_file}:"
    echo >&2 "    apollo-$apollo_number.genome.edu.au allowed_groups=\"ubuntu apollo_admin backup_user ${custom_hostname}_user\""
    exit 1
fi

if [ -z "$dryrun_str" ]; then
    # either add at first blank line after apollovms group is defined
    printf '%s\n' '0/\[apollovms\]//^$/i' "apollo-$apollo_number.genome.edu.au allowed_groups=\"ubuntu apollo_admin backup_user ${custom_hostname}_user\"" . x | ex hosts
    # OR add after last apollo-XXX... allowed_groups entry
    printf '%s\n' '0/apollovms/?apollo-....genome.edu.au allowed_groups?a' "apollo-$apollo_number.genome.edu.au allowed_groups=\"ubuntu apollo_admin backup_user ${custom_hostname}_user\"" . x | ex hosts
fi


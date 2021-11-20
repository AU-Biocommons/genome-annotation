#!/bin/bash

IFS='' read -d '' -r usage_str <<EOF
Usage: $(basename $0) apollovms_hosts_file apollo_number custom_hostname
Where:
    apollo_hosts_file = an existing inventory file containing the apollovms group
    apollo_number = 001-999
    custom_hostname = alphanumeric string with '-' allowed within string
Output:
    updated inventory file, with new apollo added to apollovms group if it isn't already defined
EOF

if [ $# -ne 3 ]; then
    echo >&2 "$usage_str"
    exit 1
fi

apollovms_hosts_file=$1
if [ ! -f $apollovms_hosts_file ]; then
    echo >&2 "The file $apollovms_hosts_file was not found! Aborting..."
    exit 1
fi

if [[ $2 =~ ^[0-9][0-9][0-9]$ ]]; then
    apollo_number=$2
    apollo_name="apollo-$apollo_number.genome.edu.au"
else
    echo >&2 "invalid apollo_number: $apollo_number"
    exit 1
fi

# allow hyphen only within string
if [[ $custom_hostname =~ ^[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]$ ]] || [[ $1 =~ ^[a-zA-Z0-9] ]]; then
    custom_hostname=$3
else
    echo >&2 "invalid custom hostname: $3"
    exit 1
fi


# grep -q (quiet) -F (pattern is a plain string)
grep -qF "$apollo_name" $apollovms_hosts_file
# grep returns 0 if a line is selected, 1 if no lines were selected, and 2 if an error occurred
existsinfile=$?

if [ $existsinfile -eq 0 ]; then
    echo >&2 "apollo-$apollo_number exists in inventory file '$apollovms_hosts_file' ... skipping"
elif [ $existsinfile -eq 1 ]; then
    # add at first blank line after apollovms group is defined
    printf '%s\n' '0/\[apollovms\]//^$/i' "apollo-$apollo_number.genome.edu.au allowed_groups=\"ubuntu apollo_admin backup_user ${custom_hostname}_user\"" . x | ex $apollovms_hosts_file
    # the other approach is to add after last apollo-XXX... allowed_groups entry
    #printf '%s\n' '0/apollovms/?apollo-....genome.edu.au allowed_groups?a' "apollo-$apollo_number.genome.edu.au allowed_groups=\"ubuntu apollo_admin backup_user ${custom_hostname}_user\"" . x | ex $apollovms_hosts_file
    echo >&2 "added apollo-$apollo_number to apollovms group in inventory file '$apollovms_hosts_file'"
else
    echo >&2 "error scanning file $apollo_hosts_file"
    exit 1
fi


#!/bin/bash

usage_str="Usage: $(basename $0) [ -a ]"

PATH="$PATH:$HOME/scripts"
today="$(date +%Y%m%d)"
ALLREPORTS=0

if [ $# -gt 0 ]; then
    if [ "$1" = "-a" ]; then
        ALLREPORTS=1
	shift
    elif [ "$1" = "-c" ]; then
	echo "clearing generated output files from today..."
	for f in apollo_usage apollo_user_organism_counts apollo_user_emails apollo_user_institutions apollo_admin_emails apollo_admin_institutions; do
	    echo "deleting ${f}-${today}.txt"
	    /bin/rm -f ${f}-${today}.txt
	done
	echo "done."
	exit 0
    else
        echo >&2 "$usage_str"
	exit 1
    fi
fi

echo "Generating data..."
echo "get users and organisms for research apollo instances (listed in list_of_apollo_instances.txt)..."
get_apollo_users_organisms.sh > apollo_usage-${today}.txt
echo "... saved to apollo_usage-${today}.txt"

echo "get summary of number of users and organisms on each apollo..."
cat apollo_usage-${today}.txt | grep ^apollo-[0-9]* > apollo_user_organism_counts-${today}.txt
echo "... saved to apollo_user_organism_counts-${today}.txt"
echo "------"
echo

echo "get last login or access time on each apollo..."
cat apollo_usage-${today}.txt | grep 'Client tokens' > apollo_last-logins-${today}.txt
echo "... saved to apollo_last-logins-${today}.txt"
echo "------"
echo

echo "Summary counts from generated data..."
echo "total number of apollos: $(grep -c '^apollo-[0-9]* Users:' apollo_user_organism_counts-${today}.txt)"
echo "total unused apollos: $(grep -c 'Organisms: 0' apollo_user_organism_counts-${today}.txt)"
cat apollo_usage-${today}.txt | grep Organisms | awk 'BEGIN { sum=0 } { cnt=$3; sum+=cnt } END { print "total number of organisms:", sum }'
echo "total published organisms: $(cat apollo_usage-${today}.txt | grep -E '[|][t]$' | wc -l)"

cat apollo_usage-${today}.txt | grep Users | awk 'BEGIN { sum=0 } { cnt=$3; sum=sum+cnt-1 } END { print "total number of users (exluding ops@qfab.org):", sum }'
echo

if [ $ALLREPORTS -eq 1 ]; then
    echo
    echo "------"
    echo "generating additional report data..."
    echo
    echo "extract apollo users emails..."
    # get apollo users emails by extracting non ops@qfab.org users from listed apollo user emails
    cat apollo_usage-${today}.txt | grep '@' | grep -v 'ops@qfab.org' | cut -d'|' -f6 | sort | uniq > apollo_user_emails-${today}.txt
    echo "... saved to apollo_user_emails-${today}.txt"
    echo

    echo "get number of users per organisation based on emails..."
cat apollo_user_emails-${today}.txt | cut -d'@' -f2 | sort | uniq -c > apollo_user_institutions-${today}.txt
    echo "... saved to apollo_user_institutions-${today}.txt"
    echo

    echo "get emails of apollo admins (not including ops@qfab.org)..."
cat apollo_usage-${today}.txt | grep '@' | grep -v 'ops@qfab.org' | grep 'ADMIN' | cut -d'|' -f6 | sort | uniq > apollo_admin_emails-${today}.txt
    echo "... saved to apollo_admin_emails-${today}.txt"
    echo

    echo "get list of organisations of apollo admins..."
cat apollo_admin_emails-${today}.txt | cut -d'@' -f2 | sort | uniq > apollo_admin_institutions-${today}.txt
    echo "... saved to apollo_admin_institutions-${today}.txt"
    echo
fi


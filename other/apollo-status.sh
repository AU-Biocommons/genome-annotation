#!/bin/bash

check_web_status() {
  group_name="$1"
  hosts="$2"

  echo "Checking $group_name:"
  for host in $hosts; do
    URL="https://${host}"
    # check status - with max time of 5s to avoid hanging
    STATUS=$(curl -s -L -o /dev/null -w "%{http_code}" --max-time 5 "$URL")

    if [[ "$STATUS" == "200" ]]; then
      echo "$host OK ($STATUS)"
    elif [[ "$STATUS" =~ ^[0-9]{3}$ ]]; then
      echo "$host ERROR ($STATUS)"
    else
      echo "$host ERROR (Timeout or Connection Failed)"
    fi
  done
}

# extract apollo and jbrowse clients from the inventory file, located with the playbooks
# on apollo-deploy this is in /opt/github-ansible/ansible/playbooks
# override if required by exporting this in the shell environment
ANSIBLE_PLAYBOOK_DIR="${ANSIBLE_PLAYBOOK_DIR:-/opt/github-ansible/ansible/playbooks}"
pushd . > /dev/null # save current directory quietly
cd $ANSIBLE_PLAYBOOK_DIR

# get list of hosts to check from inventory
client_apollos="$(ansible-inventory --list 2>/dev/null | jq -r '.clientapollos.hosts[]')"
jbrowse_clients="$(ansible-inventory --list 2>/dev/null | jq -r '.jbrowseportalhosted.hosts[]')"
#jbrowse_clients="scu.genome.edu.au degnan.genome.edu.au coral.genome.edu.au wheat-dawn.genome.edu.au"

popd > /dev/null # restore current directory quietly

# check apollos, hosted JBrowse pages on jbrowse-portal and apollo-portal
echo
check_web_status "Client Apollos" "$client_apollos"
echo
check_web_status "Client JBrowse" "$jbrowse_clients"
echo
check_web_status "Apollo Portal"  "apollo-portal.genome.edu.au"
echo
check_web_status "Apollo Monitor" "grafana.genome.edu.au"
echo

echo "Checking apollo-user-nfs:"
ssh -t apollo-user-nfs 'df -h -T | grep mnt' 2>/dev/null # username and private key specified in ~/.ssh/config
echo
#ping -c 1 -W 5 apollo-user-nfs # liveness test
#echo


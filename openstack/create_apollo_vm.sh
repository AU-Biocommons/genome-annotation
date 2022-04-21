usage_str="Usage: $(basename $0) [ -f floating_ip ] apollo_number"
floating_ip=""

if [ $# -gt 1 ] && [ "$1" = "-f" ]; then
    shift
    if [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        floating_ip="$1"
        shift
    else
        echo >&2 "invalid IP address: $1"
        exit 1
    fi
fi

if [ $# -gt 0 ] && [ "${1:0:1}" = "-" ]; then
    echo >&2 "$usage_str"
    exit 1
fi

if [ $# -ne 1 ]; then
    echo >&2 "$usage_str"
    exit 1
fi

if [[ $1 =~ ^[0-9][0-9][0-9]$ ]]; then
    apollo_number=$1
else
    echo >&2 "Error: apollo number must be 000-999"
    exit 1
fi

openstack server list > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo >&2 "Sourcing the apollo openstack environment - enter password when prompted"
  echo >&2 "source apollo-openrc.sh"
  source apollo-openrc.sh
fi

# apollo-999 is for testing only, allocate it n3.1c4r, all others get n3.8c32r
if [ "$apollo_number" -eq "999" ]; then
  flavor="649d7ca6-16be-4821-981f-c4f73eba1bff"
  apollo_name="JKL_ubuntu20_test_$(date +%Y%m%d)"
else
  flavor="649d7ca6-16be-4821-981f-c4f73eba1bff"
  apollo_name="JKL_apollo_${apollo_number}_$(date +%Y%m%d)"
fi

echo "creating apollo VM with name $apollo_name"

openstack server create \
      --flavor "$flavor" \
      --image 578525b1-f1e3-495d-b673-3a3b9cd32b23 \
      --boot-from-volume 40 \
      --key-name ga-apollo-rsa \
      --availability-zone nova \
      --nic net-id='apollo-network' \
      --security-group default \
      --security-group SSH_from_anywhere \
      --security-group Web_access \
      --security-group NRPE_from_local \
      --security-group ICMP_from_local \
      --security-group Prometheus_node_exporter_from_local \
      --security-group Prometheus_postgres_exporter_from_local \
      --security-group Postgresql \
      "$apollo_name"

if [ $? -ne 0 ]; then
  echo >&2 "Error! Failed to create VM... aborting"
  echo >&2 "Investigate error then rerun"
  exit 1
fi

echo "created apollo VM $apollo_name:"
openstack server list | grep -i "$apollo_name"

if [ -z "$floating_ip" ]; then
  echo "creating floating IP"
  openstack floating ip create 'Public external'
  #openstack floating ip list | grep None | cut -d'|' -f3 | tr -d "[:blank:]"
  floating_ip="$(openstack floating ip list | grep None | awk '{ print $4 }')"
  echo "created floating IP address: $floating_ip"
fi

openstack server add floating ip $apollo_name $floating_ip

if [ $? -ne 0 ]; then
  echo >&2 "Error! Failed to attach floating IP... aborting"
  echo >&2 "Investigate error, then manually run the following:"
  echo >&2 "openstack server add floating ip $apollo_name $floating_ip"
  exit 1
fi

echo "attached floating ip $floating_ip to apollo VM $apollo_name:"
openstack server show $apollo_name | grep addresses

echo "Done."


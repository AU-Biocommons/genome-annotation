usage_str="Usage: $(basename $0) [ -h ] [ -f floating_ip ] [ -c 1|2|4|8|16 ] name"

floating_ip=""
vcpus=""
default_vcpus="2" 

while getopts "f:c:h" opt; do
    case $opt in
        h)
            echo >&2 "$usage_str"
            exit
            ;;
        f)
            if [[ $OPTARG =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                floating_ip="$OPTARG"
            else
                echo >&2 "invalid IP address: $OPTARG"
                exit 1
            fi
            ;;
        c)
            if [[ $OPTARG =~ ^(1|2|4|8|16) ]]; then
                vcpus="$OPTARG"
            else
                echo >&2 "invalid number of vCPUs: $OPTARG"
            fi
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# get rid of option params
shift $((OPTIND-1))

# the VM name must be specified
if [ $# -ne 1 ]; then
    echo >&2 "$usage_str"
    exit 1
fi

# ensure that server name is alphanumeric incl underscore but starts with alpha and ends with alphanumeric
if [[ "$1"  =~ ^[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9]$ ]]; then
    server_name=$1
else
    echo >&2 "Error: invalid server name: must be alphanumeris including underscore but start with a letter and end with alphanumeric"
    exit 1
fi

openstack server list > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo >&2 "Sourcing the apollo openstack environment - enter password when prompted"
    echo >&2 "source apollo-openrc.sh"
    source apollo-openrc.sh
fi


# if not specified, set vcpus to 1 if server name contains _test (testing only), otherwise the default
if [ -z "$vcpus" ]; then
    if [[ "$server_name" =~ .*"_test".* ]]; then
        vcpus="1"
    else
        vcpus="$default_vcpus"
    fi
fi


# set the openstack flavor based on vcpus
case $vcpus in
    1) fname="n3.1c4r"
       flavor="649d7ca6-16be-4821-981f-c4f73eba1bff"
       ;;
    2) fname="n3.2c8r"
       flavor="506876b7-b8a3-42af-9636-e7b797b51214"
       ;;
    4) fname="n3.4c16r"
       flavor="5b51ce63-2f79-4def-af47-243a829ef9f5"
       ;;
    8) fname="n3.8c32r"
       flavor="c291f88d-6987-424b-bd6b-2b9128595c74"
       ;;
    16) fname="n3.16c64r"
       flavor="fe996a66-ecbe-4e14-9ec0-af177937acf3"
       ;;
esac

vm_name="JKL_${server_name}_$(date +%Y%m%d)"

# the following will output the image ID and name for ONLY the FIRST matching image
image_details="$(openstack image list | grep 'Pawsey - Ubuntu 22.04' | grep -v -E '(GPU|Bio)' | awk -F '|' '{  print $2, $3; exit }' | xargs)"
image_id="$(echo $image_details | cut -f 1 -d ' ')"
image_name="$(echo $image_details | cut -f 2- -d ' ')"
echo "creating VM as $fname with name $vm_name using image $image_name"

# 97c4562f-1087-4f2c-abc6-a7b02fb9f9b9 | Pawsey - Ubuntu 18.04 - 2022-05
# 67bab16e-453b-46a8-a262-c0796fa35d85 | Pawsey - Ubuntu 20.04 - 2022-05
# 435b9e2b-8de0-4d20-9e18-2f7a69c6e889 | Pawsey - Ubuntu 20.04 - 2023-06
# 9c37814e-1e77-4b47-a14e-4368420408de | Pawsey - Ubuntu 22.04 - 2022-05
# a6dede08-16b8-4c47-b348-2d0cfaa9a09a | Pawsey - Ubuntu 22.04 - 2023-06

openstack server create \
      --flavor "$flavor" \
      --image "$image_id" \
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
      "$vm_name"

if [ $? -ne 0 ]; then
    echo >&2 "Error! Failed to create VM... aborting"
    echo >&2 "Investigate error then rerun"
    exit 1
fi

echo "created VM $vm_name:"
openstack server list | grep -i "$vm_name"

if [ -z "$floating_ip" ]; then
    echo "creating floating IP"
    openstack floating ip create 'Public external'
    #openstack floating ip list | grep None | cut -d'|' -f3 | tr -d "[:blank:]"
    floating_ip="$(openstack floating ip list | grep None | awk '{ print $4 }')"
    echo "created floating IP address: $floating_ip"
fi

openstack server add floating ip $vm_name $floating_ip

if [ $? -ne 0 ]; then
    echo >&2 "Error! Failed to attach floating IP... aborting"
    echo >&2 "Investigate error, then manually run the following:"
    echo >&2 "openstack server add floating ip $vm_name $floating_ip"
    exit 1
fi

echo "attached floating ip $floating_ip to VM $vm_name:"
openstack server show $vm_name | grep addresses

echo "Done."


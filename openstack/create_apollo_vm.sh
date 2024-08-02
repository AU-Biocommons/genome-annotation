usage_str="Usage: $(basename $0) [ -h ] [ -f floating_ip ] [ -c 1|2|4|8|16 ] apollo_number"

floating_ip=""
vcpus=""
default_vcpus="4" 

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

# the apollo number must be specified
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

# if not specified, set vcpus to 1 if apollo-999 (testing only), otherwise the default
if [ -z "$vcpus" ]; then
    if [ "$apollo_number" = "999" ]; then
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

if [ "$apollo_number" = "999" ]; then
    apollo_name="JKL_ubuntu22_test_$(date +%Y%m%d)"
else
    apollo_name="JKL_apollo_${apollo_number}_$(date +%Y%m%d)"
fi

# the following will output the image ID and name for ONLY the FIRST matching image
image_details="$(openstack image list | grep 'Pawsey - Ubuntu 22.04' | grep -v -E '(GPU|Bio)' | awk -F '|' '{ print $2, $3; exit }' | xargs)"
image_id="$(echo $image_details | cut -f 1 -d ' ')"
image_name="$(echo $image_details | cut -f 2- -d ' ')"
echo "creating apollo VM as $fname with name $apollo_name using image $image_name"

# 578525b1-f1e3-495d-b673-3a3b9cd32b23 | Pawsey - Ubuntu 20.04 - 2021-02
# 67bab16e-453b-46a8-a262-c0796fa35d85 | Pawsey - Ubuntu 20.04 - 2022-05
# 435b9e2b-8de0-4d20-9e18-2f7a69c6e889 | Pawsey - Ubuntu 20.04 - 2023-06
# 6532c039-0bc6-48f0-86a7-3e3b9489f868 | Pawsey - Ubuntu 20.04 - 2024-05
# 99e4492f-7e6b-4545-8ad8-ee36b31a7db0 | Pawsey - Ubuntu 22.04 - 2024-05
#
# note that original Ubuntu 20.04 - 2021-02 image uses /dev/vda
#        --image 578525b1-f1e3-495d-b673-3a3b9cd32b23
#      2022-23 Ubuntu 20.04 - 2022-05 image uses /dev/sda
#        --image 67bab16e-453b-46a8-a262-c0796fa35d85
#      2024 Ubuntu 20.04 - 2024-05 image uses /dev/vda
#        --image 6532c039-0bc6-48f0-86a7-3e3b9489f868
#      2024 Ubuntu 22.04 - 2024-05 image uses /dev/vda
#        --image 99e4492f-7e6b-4545-8ad8-ee36b31a7db0

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
    floating_ip="$(openstack floating ip create 'Public external' | grep floating_ip_address | awk -F '|' '{ print $3 }' | xargs)"
    #openstack floating ip list | grep None | cut -d'|' -f3 | tr -d "[:blank:]"
    #floating_ip="$(openstack floating ip list | grep None | awk '{ print $4 }')"
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


#!/bin/bash

# Source OpenStack credentials
#source apollo-openrc.sh

# define keypair

#cat <<EOF >> "keylist.tf"
cat <<EOF
resource "openstack_compute_keypair_v2" "ga-apollo" {
  name       = "ga-apollo"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCxtpX/REeB0+3aHJQiPHMYB3F2I1QqKBydtBzootH6OgQIIGe+/FJnqvxkfmRVrI2IPCgh7u5IDAos91u+oMhyop+PEImd0qkcwWH6xSqGGFYphZwk3tkteIa3689JHwqENKqKD0ZvbTLRkSm7eshEwvEddzlQeBp41cVe8sJgd2pDiLT67olzjo9DSZDdGcbEIbzt+lZERqyko5yxx7qLIDwEZdQVvY2O6xpA2gfdWVewNy63500bX2pnBFx9JiFOTGR/ETAiKA7eAJ2KvS6wulkOG3FnZLD3XeF+lU2H8JjmAVDDKk1xKw9gk5IQGU8uLaeQEH19qr0WfRhgpUk5txDBhwHsltGFgajfjtGSxCC7DjRNgOEv55Mt43CfxUqyDuXXroTp2a+YDM1QlG4zP7PuD5ExPqq1E8t8DLizFMlNLYb4i4kakIB9qtZ43zMIvwYAFU8CmiYW3ZlSrOULNYz+Wi7hXK/VUR5tu402FomiKUSFB9/Ax27wDB5pzw3x+AJx265jFeida82mvEJWZgoahru/l+LF1VD0Bgb9xWphIn24aTZ1T6+qCq3L9VrtbZ0NNVOrqMnNEcxs3+au0h1E715z5N43IokabGmjv5Dep90WLcT9/yO2VJZJfqqZu/AoE1Gez5nV/3BN3FePiGJHHxPGm5nzMRjJnnJHUQ== nick@durian.localdomain"
}

EOF

### Extract and Generate Terraform config for security groups

# Get list of all security groups
security_groups=$(openstack security group list -f json)

# Loop through each security group
echo "$security_groups" | jq -c '.[]' | while read -r sg; do
  sg_id=$(echo "$sg" | jq -r '.ID')
  sg_name=$(echo "$sg" | jq -r '.Name')
  sg_description=$(echo "$sg" | jq -r '.Description')

#cat <<EOF >> "sglist.tf"
cat <<EOF
resource "openstack_networking_secgroup_v2" "${sg_name}" {
  name = "${sg_name}"
  description = "${sg_description}"
}

EOF

  # Get security group rules for this security group
  sg_rules=$(openstack security group show "$sg_id" -f json | jq -c '.rules')

  # Add rules to the security group config
  echo "$sg_rules" | jq -c '.[]' | while read -r rule; do
    direction=$(echo "$rule" | jq -r '.direction')
    ethertype=$(echo "$rule" | jq -r '.ethertype')
    protocol=$(echo "$rule" | jq -r '.protocol // empty')
    port_range_min=$(echo "$rule" | jq -r '.port_range_min // empty')
    port_range_max=$(echo "$rule" | jq -r '.port_range_max // empty')
    remote_ip_prefix=$(echo "$rule" | jq -r '.remote_ip_prefix // empty')
    remote_group_id=$(echo "$rule" | jq -r '.remote_group_id // empty')

    # name security group rule - if empty protocol (means 'Any') append ethertype (IPv4 or IPv6)
    if [ -n "$protocol" ]; then
      sec_rule_name="${sg_name}-${direction}-${protocol}"
      if [ -n "$port_range_min" ]; then
        sec_rule_name="${sec_rule_name}-${port_range_min}_${port_range_max}"
      elif [ -n "$remote_group_id" ]; then # no port range but remote group specified
        sec_rule_name="${sec_rule_name}-${remote_group_id}"
      else # no port range = 'Any' port (ICMP)
        sec_rule_name="${sec_rule_name}-Any"
      fi
    else
      sec_rule_name="${sg_name}-${direction}-${ethertype}"
    fi

#cat <<EOF >> "sglist.tf"
cat <<EOF
resource "openstack_networking_secgroup_rule_v2" "${sec_rule_name}" {
  direction = "${direction}"
  ethertype = "${ethertype}"
  protocol = "${protocol}"
  port_range_min = "${port_range_min}"
  port_range_max = "${port_range_max}"
  remote_ip_prefix = "${remote_ip_prefix}"
  remote_group_id = "${remote_group_id}"
  security_group_id = openstack_networking_secgroup_v2.${sg_name}.id
}

EOF
  done # rule
done # sg


### Extract and Generate Terraform config for servers

# Get list of servers
servers=$(openstack server list -f json)

# Loop through servers and generate Terraform config
echo "$servers" | jq -c '.[]' | while read -r server; do
  echo "processing $server ..."
  name=$(echo "$server" | jq -r '.Name')
  id=$(echo "$server" | jq -r '.ID')
  server_details=$(openstack server show "$id" -f json)
  image=$(echo $server_details | jq -r '.image')
  flavor=$(echo $server_details | jq -r '.flavor')
  network=$(echo $server_details | jq -r '.addresses | keys[]')
  avzone=$(echo $server_details | jq -r '.availability_zone')
  key=$(echo $server_details | jq -r '.key_name')
  #secgroups=$(echo $server_details | jq -r '.security_groups | map(.name) | join(", ")') # comma-separated but not quoted
  secgroups=$(echo $server_details | jq -r '[.security_groups[].name ] | @csv')
  volumes=$(echo $server_details | jq -r '.volumes_attached[] | .id')

#cat <<EOF >> "vmlist.tf"
cat <<EOF
resource "openstack_compute_instance_v2" "${name}" {
  name              = "${name}"
  image_id          = "${image}"
  flavor_name       = "${flavor}"
  key_pair          = "${key}"
  availability_zone = "${avzone}"
  network {
    name = "${network}"
  }
  security_groups   = [ $secgroups ]
}

EOF
done # server

### Extract and Generate Terraform config for volumes

# Loop through servers and generate Terraform config
for vol in $volumes; do
  vdet=$(openstack volume show "$vol" -f json)
  vdevice=$(echo $vdet | jq -r '.attachments[].device') # assume no multiattach
  vsize=$(echo $vdet | jq -r '.size')
  vname=$(echo $vdet | jq -r '.name')
  vzone=$(echo $vdet | jq -r '.availability_zone')
  # only process non-root device volumes
  if [[ "$vdevice" != "/dev/sda" && "$vdevice" != "/dev/vda" ]]; then

cat <<EOF
resource "openstack_blockstorage_volume_v2" "$vname" {
    availability_zone = "$vzone"
    name              = "$vname"
    size              = $vsize
}

resource "openstack_compute_volume_attach_v2" "${vname}-name" {
  instance_id       = openstack_compute_instance_v2.${name}.id
#  instance_id       = ${id}
  volume_id         = openstack_blockstorage_volume_v3.${vname}.id
#  volume_id         = ${v}
}

EOF
  fi # non-root device volume
done # vol



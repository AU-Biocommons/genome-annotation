# Terraform managed client apollos: tfc_apollo_XXX_YYYYMMDD
# Note: client_apollo_numbers, apollo_default_flavor and ubuntu24_image are defined in varsanddata.tf

# create a VM for each listed apollo, with names like tfc_apollo_012_20250507
resource "openstack_compute_instance_v2" "client_apollo_vms" {
    for_each          = local.client_apollo_numbers

    name              = "tfc_apollo_${each.key}_${each.value}"
    flavor_name       = lookup(local.apollo_flavors, each.key, local.apollo_default_flavor)
    key_pair          = "apollo-nectar"
    availability_zone = "ardc-syd-1"
    image_id          = data.openstack_images_image_v2.ubuntu24_image.id # lookup the image ID

    network {
        name =        "apollo-internal-network"  
    }

    security_groups = local.apollo_security_groups

    metadata = {
        description = "Terraform managed client Apollo VM"
    }

    lifecycle {
        ignore_changes  = [
            image_id  # Ignore changes to the Ubuntu 24.04 OS image ID if OS image is updated by provider
        ]
    }
}

# for each VM create a floating IP in ardc-syd IP pool
resource "openstack_networking_floatingip_v2" "client_apollo_fips" {
    for_each = openstack_compute_instance_v2.client_apollo_vms

    pool = "ardc-syd"  # IP in ardc-syd availability zone IP pool
}

# fetch the port for each VM instance based on the fixed IP
data "openstack_networking_port_v2" "client_apollo_ports" {
    for_each = openstack_compute_instance_v2.client_apollo_vms

    fixed_ip = openstack_compute_instance_v2.client_apollo_vms[each.key].network[0].fixed_ip_v4
}

# For each VM, attach the floating IP using the VM's port ID
resource "openstack_networking_floatingip_associate_v2" "client_apollo_fips_associate" {
    for_each = openstack_networking_floatingip_v2.client_apollo_fips

    floating_ip = each.value.address
    port_id     = data.openstack_networking_port_v2.client_apollo_ports[each.key].id
}


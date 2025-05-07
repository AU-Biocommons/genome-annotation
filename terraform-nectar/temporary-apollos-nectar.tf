# Terraform managed temporary apollos for testing or teaching: tft_apollo_XXX
# Note: internal_apollo_numbers, apollo_default_flavor and ubuntu24_image are defined in varsanddata.tf

# create a VM for each listed apollo, with names like tft_apollo_999
# note that date is relegated to metadata so that terraform can re-attach the same floating IP
# and these VMs get rebuilt frequently
resource "openstack_compute_instance_v2" "temporary_apollo_vms" {
    for_each          = local.temporary_apollo_numbers

    name              = "tft_apollo_${each.key}"
    #flavor_name       = each.key == "999" ? "r3.small" : "r3.medium"  # 2c8r or 4c16r
    flavor_name       = lookup(local.apollo_flavors, each.key, local.apollo_default_flavor)
    key_pair          = "apollo-nectar"
    availability_zone = "ardc-syd-1"
    image_id          = data.openstack_images_image_v2.ubuntu24_image.id # lookup the image ID

    network {
        name =        "apollo-internal-network"  
    }

    security_groups = local.apollo_security_groups

    metadata = {
        description   = "Terraform managed temporary Apollo VM"
        creation_date = "${each.value}"
    }

    # ensure floating IP will not be destroyed with the VM
    lifecycle {
        create_before_destroy = true
        ignore_changes  = [
            image_id  # Ignore changes to the Ubuntu 24.04 OS image ID if OS image is updated by provider
        ]
    }
}

# for each VM create a floating IP in ardc-syd IP pool
resource "openstack_networking_floatingip_v2" "temporary_apollo_fips" {
    for_each = openstack_compute_instance_v2.temporary_apollo_vms
    pool = "ardc-syd"  # IP in ardc-syd availability zone IP pool

    # prevent the floating IP from being destroyed when the VM is destroyed
    lifecycle {
        prevent_destroy = true
    }
}

# fetch the port for each VM instance based on the fixed IP
data "openstack_networking_port_v2" "temporary_apollo_ports" {
    for_each = openstack_compute_instance_v2.temporary_apollo_vms
    fixed_ip = openstack_compute_instance_v2.temporary_apollo_vms[each.key].network[0].fixed_ip_v4
}

# for each VM, attach the floating IP using the VM's port ID
resource "openstack_networking_floatingip_associate_v2" "temporary_apollo_fips_associate" {
    for_each = openstack_networking_floatingip_v2.temporary_apollo_fips

    floating_ip = each.value.address
    port_id     = data.openstack_networking_port_v2.temporary_apollo_ports[each.key].id

    # ensure that the floating IP is reassociated with the new VM when the VM is recreated
    lifecycle {
        create_before_destroy = true
    }
}


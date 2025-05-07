# Terraform managed internal apollos: tfi_apollo_XXX_YYYYMMDD
# Note: internal_apollo_numbers, apollo_default_flavor and ubuntu24_image are defined in varsanddata.tf

# create a VM for each listed apollo, with names like tfi_apollo_011_20250501
resource "openstack_compute_instance_v2" "internal_apollo_vms" {
    for_each          = local.internal_apollo_numbers

    name              = "tfi_apollo_${each.key}_${each.value}"
    flavor_name       = lookup(local.apollo_flavors, each.key, local.apollo_default_flavor)
    key_pair          = "apollo-nectar"
    availability_zone = "ardc-syd-1"
    image_id          = data.openstack_images_image_v2.ubuntu24_image.id # lookup the image ID

    network {
        name =        "apollo-internal-network"  
    }

    security_groups = local.apollo_security_groups

    metadata = {
        description = "Terraform managed internal Apollo VM"
    }

    lifecycle {
        ignore_changes  = [
            image_id  # Ignore changes to the Ubuntu 24.04 OS image ID if OS image is updated by provider
        ]
    }
}

# for each VM create a floating IP in ardc-syd IP pool
resource "openstack_networking_floatingip_v2" "internal_apollo_fips" {
    for_each = openstack_compute_instance_v2.internal_apollo_vms

    pool = "ardc-syd"  # IP in ardc-syd availability zone IP pool
}

# fetch the port for each VM instance based on the fixed IP
data "openstack_networking_port_v2" "internal_apollo_ports" {
    for_each = openstack_compute_instance_v2.internal_apollo_vms

    fixed_ip = openstack_compute_instance_v2.internal_apollo_vms[each.key].network[0].fixed_ip_v4
}

# For each VM, attach the floating IP using the VM's port ID
resource "openstack_networking_floatingip_associate_v2" "internal_apollo_fips_associate" {
    for_each = openstack_networking_floatingip_v2.internal_apollo_fips

    floating_ip = each.value.address
    port_id     = data.openstack_networking_port_v2.internal_apollo_ports[each.key].id
}


# create 100GB volume for apollo builds, to be attached to apollo-011
resource "openstack_blockstorage_volume_v3" "apollo_build_volume" {
    name              = "Apollo-Build"
    size              = 100  # Size of the volume in GB
    availability_zone = "ardc-syd-1"
    description       = "100GB volume for apollo-011 instance"
    depends_on        = [openstack_compute_instance_v2.internal_apollo_vms["011"]]
}

# attach Apollo-Build volume to apollo-011 instance
resource "openstack_compute_volume_attach_v2" "apollo_011_volume_attach" {
    instance_id  = openstack_compute_instance_v2.internal_apollo_vms["011"].id
    volume_id    = openstack_blockstorage_volume_v3.apollo_build_volume.id
    device       = "/dev/vdb"  # attach volume to /dev/vdb
}


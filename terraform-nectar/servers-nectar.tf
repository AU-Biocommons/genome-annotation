# Terraform managed servers: tfs_apollo_NAME_YYYYMMDD

# backup/deploy server VM
resource "openstack_compute_instance_v2" "tfs_apollo_backup_20250430" {
    name              = "tfs_apollo_backup_20250430"
    flavor_name       = "m3.large"
    key_pair          = "apollo-nectar"
    availability_zone = "ardc-syd-1"

    block_device {          # define boot volume with custom size
        uuid                  = "49f677df-01e5-45c9-9611-609ef21f60e1" # NeCTAR Ubuntu 24.04 LTS (Noble) amd64
        source_type           = "image"
        volume_size           = 50
        boot_index            = 0
        destination_type      = "volume"
        delete_on_termination = true
    }

    network {
        name =        "apollo-internal-network"  
    }

    security_groups = [
        "default",
        "SSH_access",
        "NRPE_local_access",
        "ICMP_local_access",
        "Postgresql_allowed_group"
    ]

    metadata = {
        description = "Backup server for Apollo project"
    }

    lifecycle {
        prevent_destroy = true
    }
}

# create floating IP in ardc-syd IP pool
resource "openstack_networking_floatingip_v2" "apollo_backup_fip" {
    pool = "ardc-syd"  # IP in ardc-syd availability zone IP pool
}

# fetch the port for VM instance based on the fixed IP
data "openstack_networking_port_v2" "apollo_backup_port" {
    fixed_ip = openstack_compute_instance_v2.tfs_apollo_backup_20250430.network[0].fixed_ip_v4
}

# attach floating IP using the VM port ID
resource "openstack_networking_floatingip_associate_v2" "apollo_backup_fip_assoc" {
    floating_ip = openstack_networking_floatingip_v2.apollo_backup_fip.address
    port_id     = data.openstack_networking_port_v2.apollo_backup_port.id
}

/*
# attach IP to VM (deprecated method - for reference)
resource "openstack_compute_floatingip_associate_v2" "apollo_backup_fip_assoc" {
    depends_on  = [openstack_compute_instance_v2.tfs_apollo_backup_20250430]
    floating_ip = openstack_networking_floatingip_v2.apollo_backup_fip.address
    instance_id = openstack_compute_instance_v2.tfs_apollo_backup_20250430.id
}
*/

/*
# WARNING: volume is NOT managed by terraform to prevent accidental deletion! manual attachment required!
# attach backups volume to VM
resource "openstack_compute_volume_attach_v2" "apollo_backups_vol" {
    instance_id       = openstack_compute_instance_v2.tfs_apollo_backup_20250430.id
    volume_id         = openstack_blockstorage_volume_v3.apollo_backups_vol.id
    device	      = "/dev/vdb"
}
*/


# variables and data common across multiple .tf files
# or useful to have in one place for reference and ease of use
# this is the only file that will need regular changes

# WARNING: commenting out or removing an apollo number will result in DELETION of that apollo!!!

locals {
    # temporary and teaching Apollo instance numbers and creation date: tft_apollo_XXX
    temporary_apollo_numbers = {
    #    "005" = "2025MMDD",
    #    "023" = "2025MMDD",
        "999" = "20250603"
    }

    # internal Apollo instance numbers and creation date: tfi_apollo_XXX_YYYYMMDD
    internal_apollo_numbers = {
    #    "001" = "2025MMDD",
    #    "004" = "202505DD",
        "011" = "20250501"
    }

    # client Apollo instance numbers and creation date: tfc_apollo_XXX_YYYYMMDD
    client_apollo_numbers = {
        "003" = "20250604",
        "016" = "20250604",
        "017" = "20250604",
        "021" = "20250604",
        "022" = "20250604",
        "024" = "20250604",
        "025" = "20250604",
        "030" = "20250604",
        "035" = "20250604"
    }

    # apollos with non-default (4c16r r3.medium) flavor
    # 2c8r r3.small for testing, 8c32r r3.large for high load, 8c16r m3.medium for compiling
    # WARNING: changes to flavor will result in VM being recreated
    apollo_default_flavor = "r3.medium"
    apollo_flavors = {
        "011" = "m3.large",
        #"020" = "r3.large",
        "035" = "r3.large",
        "999" = "r3.small"
    }

    # security groups required for apollo instances (DO NOT CHANGE UNLESS NEEDED for Grafana for eg)
    # while some are only required for specific instances,
    # for managing many apollos, they can all have the additional groups
    # (ufw will block these if not configured on the apollo instance)
    apollo_security_groups = [
        "default",
        "SSH_access",
        "Web_Server_access_full",
        "Postgresql_Server_local_access",
        "SequenceServer_Web_access",
        "Apollo3_Server_access",
        "NRPE_local_access",
        "ICMP_local_access"
    ]
}


# the following allows us to look up the OS image by name, which means that
# we'll always use the latest update of the image when we create a new VM
# but requires changes to image_id to be ignored in VM with
#   lifecycle { ignore_changes= [ image_id ] }

data "openstack_images_image_v2" "ubuntu24_image" {
    name = "NeCTAR Ubuntu 24.04 LTS (Noble) amd64"
}



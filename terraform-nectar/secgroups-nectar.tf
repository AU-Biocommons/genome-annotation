# ssh access security group
resource "openstack_networking_secgroup_v2" "SSH_access" {
    description = "Allow SSH access"
    name        = "SSH_access"
}

# ssh security group rules
resource "openstack_networking_secgroup_rule_v2" "SSH_access-ingress-tcp-22" {
    direction         = "ingress"
    ethertype         = "IPv4"
    port_range_min    = 22
    port_range_max    = 22
    protocol          = "tcp"
    remote_ip_prefix  = "0.0.0.0/0"
    security_group_id = openstack_networking_secgroup_v2.SSH_access.id
}

# web server access security group
resource "openstack_networking_secgroup_v2" "Web_Server_access_full" {
    description = "Allow http(s) access on ports 80, 443, 8080"
    name        = "Web_Server_access_full"
}

# web server access security group rules
resource "openstack_networking_secgroup_rule_v2" "Web_Server_access_full-ingress-tcp-80" {
    direction         = "ingress"
    ethertype         = "IPv4"
    port_range_min    = 80
    port_range_max    = 80
    protocol          = "tcp"
    remote_ip_prefix  = "0.0.0.0/0"
    security_group_id = openstack_networking_secgroup_v2.Web_Server_access_full.id
}

resource "openstack_networking_secgroup_rule_v2" "Web_Server_access_full-ingress-tcp-443" {
    direction         = "ingress"
    ethertype         = "IPv4"
    port_range_min    = 443
    port_range_max    = 443
    protocol          = "tcp"
    remote_ip_prefix  = "0.0.0.0/0"
    security_group_id = openstack_networking_secgroup_v2.Web_Server_access_full.id
}

resource "openstack_networking_secgroup_rule_v2" "Web_Server_access_full-ingress-tcp-8080" {
    direction         = "ingress"
    ethertype         = "IPv4"
    port_range_min    = 8080
    port_range_max    = 8080
    protocol          = "tcp"
    remote_ip_prefix  = "0.0.0.0/0"
    security_group_id = openstack_networking_secgroup_v2.Web_Server_access_full.id
}

# Globus Connect Server data transfer security group
resource "openstack_networking_secgroup_v2" "Globus_Connect_access" {
    description = "Globus Connect Server access to ports 50000-51000"
    name        = "Globus_Connect_access"
}

# Globus_access security group rules
resource "openstack_networking_secgroup_rule_v2" "Globus_Connect_access-ingress-tcp-50000_51000" {
    direction         = "ingress"
    ethertype         = "IPv4"
    port_range_min    = 50000
    port_range_max    = 51000
    protocol          = "tcp"
    remote_ip_prefix  = "0.0.0.0/0"
    security_group_id = openstack_networking_secgroup_v2.Globus_Connect_access.id
}

# NFS Server security group rules
resource "openstack_networking_secgroup_v2" "NFS_Server_local_access" {
    name = "NFS_Server_local_access"
    description = "NFS Server local access on ports 111, 2049, 50003"
}

resource "openstack_networking_secgroup_rule_v2" "NFS_Server_local_access-ingress-tcp-111" {
    direction = "ingress"
    ethertype = "IPv4"
    protocol = "tcp"
    port_range_min = "111"
    port_range_max = "111"
    remote_ip_prefix = "192.168.0.0/24"
    security_group_id = openstack_networking_secgroup_v2.NFS_Server_local_access.id
} 

resource "openstack_networking_secgroup_rule_v2" "NFS_Server_local_access-ingress-udp-111" {
    direction = "ingress"
    ethertype = "IPv4"
    protocol = "udp"
    port_range_min = "111"
    port_range_max = "111"
    remote_ip_prefix = "192.168.0.0/24"
    security_group_id = openstack_networking_secgroup_v2.NFS_Server_local_access.id
} 

resource "openstack_networking_secgroup_rule_v2" "NFS_Server_local_access-ingress-tcp-2049" {
    direction = "ingress"
    ethertype = "IPv4"
    protocol = "tcp"
    port_range_min = "2049"
    port_range_max = "2049"
    remote_ip_prefix = "192.168.0.0/24"
    security_group_id = openstack_networking_secgroup_v2.NFS_Server_local_access.id
} 

resource "openstack_networking_secgroup_rule_v2" "NFS_Server_local_access-ingress-tcp-50003" {
    direction = "ingress"
    ethertype = "IPv4"
    protocol = "tcp"
    port_range_min = "50003"
    port_range_max = "50003"
    remote_ip_prefix = "192.168.0.0/24"
    security_group_id = openstack_networking_secgroup_v2.NFS_Server_local_access.id
}

resource "openstack_networking_secgroup_rule_v2" "NFS_Server_local_access-ingress-udp-50003" {
    direction = "ingress"
    ethertype = "IPv4"
    protocol = "udp"
    port_range_min = "50003"
    port_range_max = "50003"
    remote_ip_prefix = "192.168.0.0/24"
    security_group_id = openstack_networking_secgroup_v2.NFS_Server_local_access.id
}

/*
# PostgreSQL Server security group rules
resource "openstack_networking_secgroup_v2" "Postgresql_Server_local_access" {
    name = "Postgresql_Server_local_access"
    description = "Postgresql server local access on port 5432"
}
  
resource "openstack_networking_secgroup_rule_v2" "Postgresql_Server_local_access-ingress-tcp-5432" {
    direction = "ingress"
    ethertype = "IPv4"
    protocol = "tcp" 
    port_range_min = "5432"
    port_range_max = "5432"
    remote_ip_prefix = "192.168.0.0/24"
    # remote_group_id  = openstack_networking_secgroup_v2.Postgresql_Server_local_access.id # self-referential
    security_group_id = openstack_networking_secgroup_v2.Postgresql_Server_local_access.id
}
*/

# Define referential security group from which PostgreSQL connections are allowed (ie apollo-backup)
resource "openstack_networking_secgroup_v2" "Postgresql_allowed_group" {
  name        = "Postgresql_allowed_group"
  description = "Members of this security group can connect to Postgres on VMs belonging to group Postgresql_Server_local_access"
}

resource "openstack_networking_secgroup_rule_v2" "Postgresql_allowed_group-outbound-tcp-5432" {
  direction        = "egress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = "5432"
  port_range_max   = "5432"
  remote_group_id  = openstack_networking_secgroup_v2.Postgresql_Server_local_access.id # Allow connections to PostgreSQL on Apollo VMs
  security_group_id = openstack_networking_secgroup_v2.Postgresql_allowed_group.id
}

# Define PostgreSQL security group for VMs to which connections are allowed (ie apollo VMs and django-portal)
resource "openstack_networking_secgroup_v2" "Postgresql_Server_local_access" {
  name        = "Postgresql_Server_local_access"
  description = "Allow PostgreSQL connections from allowed local VMs"
}

resource "openstack_networking_secgroup_rule_v2" "Postgresql_Server_local_access-ingress-tcp-5432" {
  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = "5432"
  port_range_max   = "5432"
  remote_group_id  = openstack_networking_secgroup_v2.Postgresql_allowed_group.id # Allow connections from Apollo Backup VM
  security_group_id = openstack_networking_secgroup_v2.Postgresql_Server_local_access.id
}

# ICMP (ping) security group rules
resource "openstack_networking_secgroup_v2" "ICMP_local_access" {
    name = "ICMP_local_access"
    description = "Allow ICMP (ping) from local network"
}

resource "openstack_networking_secgroup_rule_v2" "ICMP_local_access-ingress-icmp-Any" {
    direction = "ingress"
    ethertype = "IPv4"
    protocol = "icmp"
    remote_ip_prefix = "192.168.0.0/24"
    security_group_id = openstack_networking_secgroup_v2.ICMP_local_access.id
}

# SequenceServer security group rules
resource "openstack_networking_secgroup_v2" "SequenceServer_Web_access" {
    name = "SequenceServer_Web_access"
    description = "SequenceServer web access on port 4567"
} 

resource "openstack_networking_secgroup_rule_v2" "SequenceServer_Web_access-ingress-tcp-4567" {
    direction = "ingress"
    ethertype = "IPv4"
    protocol = "tcp"
    port_range_min = "4567"
    port_range_max = "4567"
    remote_ip_prefix = "0.0.0.0/0"
    security_group_id = openstack_networking_secgroup_v2.SequenceServer_Web_access.id
}

# Apollo3 security group rules
resource "openstack_networking_secgroup_v2" "Apollo3_Server_access" {
    name = "Apollo3_Server_access"
    description = "Allow connections to Apollo3 Server and plugins on ports 3999 and 9000"
}

resource "openstack_networking_secgroup_rule_v2" "Apollo3_Server_access-ingress-tcp-3999" {
    direction = "ingress"
    ethertype = "IPv4"
    protocol = "tcp"
    port_range_min = "3999"
    port_range_max = "3999"
    remote_ip_prefix = "0.0.0.0/0"
    security_group_id = openstack_networking_secgroup_v2.Apollo3_Server_access.id
}

resource "openstack_networking_secgroup_rule_v2" "Apollo3_Server_access-ingress-tcp-9000" {
    direction = "ingress"
    ethertype = "IPv4"
    protocol = "tcp"
    port_range_min = "9000"
    port_range_max = "9000"
    remote_ip_prefix = "0.0.0.0/0"
    security_group_id = openstack_networking_secgroup_v2.Apollo3_Server_access.id
}

# NRPE (Nagios) security group rules
resource "openstack_networking_secgroup_v2" "NRPE_local_access" {
    name = "NRPE_local_access"
    description = "Allow local NRPE connections from Nagios on port 5666"
} 

resource "openstack_networking_secgroup_rule_v2" "NRPE_local_access-ingress-tcp-5666" {
    direction = "ingress"
    ethertype = "IPv4"
    protocol = "tcp"
    port_range_min = "5666"
    port_range_max = "5666"
    remote_ip_prefix = "192.168.0.0/24"
    security_group_id = openstack_networking_secgroup_v2.NRPE_local_access.id
}

# Prometheus server (Grafana) security group rules
resource "openstack_networking_secgroup_v2" "Prometheus_Server_local_access" {
    name = "Prometheus_Server_local_access"
    description = "Allow local Prometheus connections on port 9090 and 9100 (node-exporter)"
}

# Rule for general Prometheus connections
resource "openstack_networking_secgroup_rule_v2" "Prometheus_Server_local_access-ingress-tcp-9090" {
    direction = "ingress"
    ethertype = "IPv4"
    protocol = "tcp"
    port_range_min = "9090"
    port_range_max = "9090"
    remote_ip_prefix = "192.168.0.0/24"
    security_group_id = openstack_networking_secgroup_v2.Prometheus_Server_local_access.id
}

# rule for Prometheus Node Exporter
resource "openstack_networking_secgroup_rule_v2" "Prometheus_Server_local_access-node_exporter-ingress-tcp-9100" {
    direction = "ingress"
    ethertype = "IPv4"
    protocol = "tcp"
    port_range_min = "9100"
    port_range_max = "9100"
    remote_ip_prefix = "192.168.0.0/24"
    security_group_id = openstack_networking_secgroup_v2.Prometheus_Server_local_access.id
}

/*** TODO: define this ONLY if it is used
# rule for Prometheus Postgres Exporter
resource "openstack_networking_secgroup_rule_v2" "Prometheus_Server_local_access-postgres_exporter-ingress-tcp-9187" {
    direction = "ingress"
    ethertype = "IPv4"
    protocol = "tcp"
    port_range_min = "9187"
    port_range_max = "9187"
    remote_ip_prefix = "192.168.0.0/24"
    security_group_id = openstack_networking_secgroup_v2.Prometheus_Server_local_access.id
}
***/

# Prometheus Web access security group rules
resource "openstack_networking_secgroup_v2" "Prometheus_Server_Web_access" {
    name = "Prometheus_Server_Web_access"
    description = "Prometheus Server Web UI access on port 9090"
}

resource "openstack_networking_secgroup_rule_v2" "Prometheus_Server_Web_access-ingress-tcp-9090" {
    direction = "ingress"
    ethertype = "IPv4"
    protocol = "tcp"
    port_range_min = "9090"
    port_range_max = "9090"
    remote_ip_prefix = "0.0.0.0/0"
    security_group_id = openstack_networking_secgroup_v2.Prometheus_Server_Web_access.id
}

# Grafana Web access security group rules
resource "openstack_networking_secgroup_v2" "Grafana_Server_Web_access" {
    name = "Grafana_Server_Web_access"
    description = "Grafana Server Web UI access on port 3000"
} 

resource "openstack_networking_secgroup_rule_v2" "Grafana_Server_Web_access-ingress-tcp-3000" {
    direction = "ingress"
    ethertype = "IPv4"
    protocol = "tcp"
    port_range_min = "3000"
    port_range_max = "3000"
    remote_ip_prefix = "0.0.0.0/0"
    security_group_id = openstack_networking_secgroup_v2.Grafana_Server_Web_access.id
} 


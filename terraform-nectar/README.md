Terraform files and VM naming scheme
  - apollo-varsanddata.tf: variables and data for creating apollos
  - servers-nectar.tf:  tfs_ terraform managed servers - infrastructure only with prevent_destroy
  - internal-apollos-nectar.tf: tfi_ terraform managed internal apollo/jbrowse sandpits
  - temporary-apollos-nectar - tft_ terraform managed temp teaching and test apollos - to be recreated often
  - client-apollos-nectar.tf: tfc_ terraform managed client apollo/jbrowse
  - secgroups-nectar.tf: security group definitions
  - providers.tf: terraform openstack provider definition
  - large-volumes-nectar_not_managed.txt: large volumes not managed by Terraform
  - test-vm-definition.txt: testing terraform VM definitions - rename extension to use

Note that these are dependent on the internal network apollo-internal-network 192.168.0.*
being created manually beforehand.


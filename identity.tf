#resource "oci_identity_dynamic_group" "k3s" {
#  compartment_id = var.tenancy_ocid
#  description    = "Dynamic Group to give k3s nodes permission to manage Load Balancers"
#  matching_rule  = "All { instance.id = '${oci_core_instance.master.id}', instance.compartment.id = '${oci_identity_compartment.k3s.id}' }"
#  name           = "k3s"
#}
#
#resource "oci_identity_policy" "k3s_load_balancer" {
#  compartment_id = var.tenancy_ocid
#  description    = "Policy to allow k3s nodes to manage load balancer"
#  name           = "k3s-load-balancer"
#  statements = [
#    "Allow dynamic-group ${oci_identity_dynamic_group.k3s.name} to read instance-family in compartment ${oci_identity_compartment.k3s.name}",
#    "Allow dynamic-group ${oci_identity_dynamic_group.k3s.name} to use virtual-network-family in compartment ${oci_identity_compartment.k3s.name}",
#    "Allow dynamic-group ${oci_identity_dynamic_group.k3s.name} to manage load-balancers in compartment ${oci_identity_compartment.k3s.name}",
#    "Allow dynamic-group ${oci_identity_dynamic_group.k3s.name} to manage security-lists in compartment ${oci_identity_compartment.k3s.name}"
#  ]
#}

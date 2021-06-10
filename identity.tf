resource "oci_identity_dynamic_group" "test_dynamic_group" {
  compartment_id = var.tenancy_ocid
  description    = "Dynamic Group to give k3s nodes permission to manage Load Balancers"
  matching_rule  = "All { Any { instance.id = '${oci_core_instance.master.id}', instance.id = '${oci_core_instance.worker1.id}', instance.id = '${oci_core_instance.worker2.id}' }, instance.compartment.id = '${oci_identity_compartment.k3s.id}' }"
  name           = "k3s"
}

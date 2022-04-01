resource "oci_identity_dynamic_group" "kubernetes" {
  compartment_id = var.tenancy_ocid
  description    = "Dynamic Group to give Kubernetes nodes permission to manage Load Balancers"
  matching_rule  = "All { instance.id = '${oci_core_instance.kubernetes_control_plane.id}', instance.compartment.id = '${oci_identity_compartment.kubernetes.id}' }"
  name           = "kubernetes"
}

resource "oci_identity_policy" "load_balancer" {
  compartment_id = var.tenancy_ocid
  description    = "Policy to allow Kubernetes nodes to manage load balancers"
  name           = "kubernetes-load-balancer"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.kubernetes.name} to read instance-family in compartment ${oci_identity_compartment.kubernetes.name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.kubernetes.name} to use virtual-network-family in compartment ${oci_identity_compartment.kubernetes.name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.kubernetes.name} to manage load-balancers in compartment ${oci_identity_compartment.kubernetes.name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.kubernetes.name} to manage security-lists in compartment ${oci_identity_compartment.kubernetes.name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.kubernetes.name} to manage network-security-groups in compartment ${oci_identity_compartment.kubernetes.name}"
  ]
}

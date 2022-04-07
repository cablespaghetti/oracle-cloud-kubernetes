resource "oci_identity_compartment" "kubernetes" {
  compartment_id = var.tenancy_ocid
  description    = "Compartment for Terraform resources."
  name           = var.environment_name
  enable_delete  = true
  freeform_tags  = local.freeform_tags
}

resource "oci_identity_dynamic_group" "kubernetes_control_plane" {
  compartment_id = var.tenancy_ocid
  description    = "Dynamic group which contains all instance in this compartment"
  matching_rule  = "All {instance.compartment.id = '${oci_identity_compartment.kubernetes.id}'}"
  name           = "kubernetes_control_plane"
  freeform_tags  = local.freeform_tags
}

resource "oci_identity_policy" "kubernetes_control_plane" {
  compartment_id = var.tenancy_ocid
  description    = "Policy to allow ${oci_identity_dynamic_group.kubernetes_control_plane.name} use OCI API"
  name           = "kubernetes_control_plane"
  statements = [
    "allow dynamic-group ${oci_identity_dynamic_group.kubernetes_control_plane.name} to read instance-family in tenancy",
    "allow dynamic-group ${oci_identity_dynamic_group.kubernetes_control_plane.name} to read compute-management-family in tenancy"
  ]
  freeform_tags = local.freeform_tags
}

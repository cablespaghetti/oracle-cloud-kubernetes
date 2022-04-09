resource "oci_identity_compartment" "kubernetes" {
  compartment_id = var.tenancy_ocid
  description    = "Compartment for Terraform resources."
  name           = var.environment_name
  enable_delete  = true
  freeform_tags  = local.freeform_tags
}

resource "oci_identity_tag_namespace" "security" {
  compartment_id = oci_identity_compartment.kubernetes.id
  description    = "Tags used to assign identity policies via dynamic groups"
  name           = "Security"
}

resource "oci_identity_tag" "instance_group" {
  description      = "Used to define the group of instances to determine dynamic group membership"
  name             = "Instance-Group"
  tag_namespace_id = oci_identity_tag_namespace.security.id
}

resource "oci_identity_dynamic_group" "kubernetes_control_plane" {
  compartment_id = var.tenancy_ocid
  description    = "Dynamic group which contains instances tagged as Kubernetes Control Plane nodes"
  matching_rule  = <<EOT
  All {
    instance.compartment.id = '${oci_identity_compartment.kubernetes.id}',
    tag.Security.Instance-Group.value = 'kubernetes_control_plane'
  }
EOT
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

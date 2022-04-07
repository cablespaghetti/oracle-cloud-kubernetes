resource "oci_load_balancer_load_balancer" "kubernetes_control_plane" {
  compartment_id = oci_identity_compartment.kubernetes.id
  display_name   = "kubernetes_control_plane"
  subnet_ids     = [oci_core_subnet.private.id]
  shape          = "flexible"

  freeform_tags              = local.freeform_tags
  is_private                 = true
  network_security_group_ids = [oci_core_network_security_group.kubernetes.id]
  shape_details {
    maximum_bandwidth_in_mbps = 10
    minimum_bandwidth_in_mbps = 10
  }
}

resource "oci_load_balancer_backend_set" "kubernetes_control_plane" {
  health_checker {
    protocol = "TCP"
    port     = 6443
  }
  name             = "kubernetes_control_plane"
  load_balancer_id = oci_load_balancer_load_balancer.kubernetes_control_plane.id
  policy           = "LEAST_CONNECTIONS"
}

resource "oci_load_balancer_listener" "kubernetes_control_plane" {
  default_backend_set_name = oci_load_balancer_backend_set.kubernetes_control_plane.name
  name                     = "kubernetes_control_plane"
  load_balancer_id         = oci_load_balancer_load_balancer.kubernetes_control_plane.id
  port                     = 6443
  protocol                 = "TCP"
}

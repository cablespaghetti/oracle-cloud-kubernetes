resource "oci_load_balancer_load_balancer" "kubernetes" {
  compartment_id = oci_identity_compartment.kubernetes.id
  display_name   = var.environment_name
  subnet_ids     = [oci_core_subnet.public.id]
  shape          = "flexible"

  freeform_tags              = local.freeform_tags
  network_security_group_ids = [oci_core_network_security_group.kubernetes_lb.id]
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
  name             = local.resource_name
  load_balancer_id = oci_load_balancer_load_balancer.kubernetes.id
  policy           = "LEAST_CONNECTIONS"
}

resource "oci_load_balancer_listener" "kubernetes_control_plane" {
  default_backend_set_name = oci_load_balancer_backend_set.kubernetes_control_plane.name
  name                     = local.resource_name
  load_balancer_id         = oci_load_balancer_load_balancer.kubernetes.id
  port                     = 6443
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "kubernetes_https" {
  health_checker {
    protocol = "TCP"
    port     = 443
  }
  name             = "${var.environment_name}-https"
  load_balancer_id = oci_load_balancer_load_balancer.kubernetes.id
  policy           = "LEAST_CONNECTIONS"
}

resource "oci_load_balancer_listener" "kubernetes_https" {
  default_backend_set_name = oci_load_balancer_backend_set.kubernetes_https.name
  name                     = "${var.environment_name}-https"
  load_balancer_id         = oci_load_balancer_load_balancer.kubernetes.id
  port                     = 443
  protocol                 = "TCP"
}

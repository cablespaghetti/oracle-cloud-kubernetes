data "oci_core_images" "kubernetes" {
  compartment_id           = oci_identity_compartment.kubernetes.id
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_network_security_group" "kubernetes" {
  compartment_id = oci_identity_compartment.kubernetes.id
  vcn_id         = module.vcn.vcn_id
  display_name   = local.resource_name
  freeform_tags  = local.freeform_tags
}

resource "oci_core_network_security_group" "kubernetes_lb" {
  compartment_id = oci_identity_compartment.kubernetes.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "${local.resource_name}-lb"
  freeform_tags  = local.freeform_tags
}

resource "oci_core_network_security_group_security_rule" "kubernetes_ingress_ssh_bastion" {
  network_security_group_id = oci_core_network_security_group.kubernetes.id
  protocol                  = 6
  direction                 = "INGRESS"
  source                    = local.private_cidr
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "kubernetes_ingress_apiserver" {
  network_security_group_id = oci_core_network_security_group.kubernetes.id
  protocol                  = 6
  direction                 = "INGRESS"
  source                    = oci_core_network_security_group.kubernetes.id
  source_type               = "NETWORK_SECURITY_GROUP"
  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "kubernetes_ingress_metrics" {
  network_security_group_id = oci_core_network_security_group.kubernetes.id
  protocol                  = 6
  direction                 = "INGRESS"
  source                    = oci_core_network_security_group.kubernetes.id
  source_type               = "NETWORK_SECURITY_GROUP"
  tcp_options {
    destination_port_range {
      min = 10250
      max = 10250
    }
  }
}

resource "oci_core_network_security_group_security_rule" "kubernetes_ingress_flannel" {
  network_security_group_id = oci_core_network_security_group.kubernetes.id
  protocol                  = 17
  direction                 = "INGRESS"
  source                    = oci_core_network_security_group.kubernetes.id
  source_type               = "NETWORK_SECURITY_GROUP"
  udp_options {
    destination_port_range {
      min = 8472
      max = 8472
    }
  }
}

resource "oci_core_network_security_group_security_rule" "kubernetes_ingress_etcd" {
  network_security_group_id = oci_core_network_security_group.kubernetes.id
  protocol                  = 6
  direction                 = "INGRESS"
  source                    = oci_core_network_security_group.kubernetes.id
  source_type               = "NETWORK_SECURITY_GROUP"
  tcp_options {
    destination_port_range {
      min = 2379
      max = 2380
    }
  }
}

resource "oci_core_network_security_group_security_rule" "kubernetes_egress" {
  network_security_group_id = oci_core_network_security_group.kubernetes.id
  protocol                  = "all"
  direction                 = "EGRESS"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "kubernetes_ingress_apiserver_lb" {
  network_security_group_id = oci_core_network_security_group.kubernetes.id
  protocol                  = 6
  direction                 = "INGRESS"
  source                    = oci_core_network_security_group.kubernetes_lb.id
  source_type               = "NETWORK_SECURITY_GROUP"
  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "kubernetes_ingress_https_lb" {
  network_security_group_id = oci_core_network_security_group.kubernetes.id
  protocol                  = 6
  direction                 = "INGRESS"
  source                    = oci_core_network_security_group.kubernetes_lb.id
  source_type               = "NETWORK_SECURITY_GROUP"
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "kubernetes_lb_egress" {
  network_security_group_id = oci_core_network_security_group.kubernetes_lb.id
  protocol                  = "all"
  direction                 = "EGRESS"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "kubernetes_lb_ingress_apiserver_internet" {
  network_security_group_id = oci_core_network_security_group.kubernetes_lb.id
  protocol                  = 6
  direction                 = "INGRESS"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "kubernetes_lb_ingress_https_internet" {
  network_security_group_id = oci_core_network_security_group.kubernetes_lb.id
  protocol                  = 6
  direction                 = "INGRESS"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

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
  display_name   = "kubernetes"
}

resource "oci_core_network_security_group_security_rule" "kubernetes_ingress_ssh" {
  network_security_group_id = oci_core_network_security_group.kubernetes.id
  protocol                  = 6
  direction                 = "INGRESS"
  source                    = local.bastion_cidr
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
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

data "cloudinit_config" "kubernetes_control_plane" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "control_plane.yaml"
    content_type = "text/cloud-config"
    content      = <<EOT
runcmd:
 - curl -sfL https://get.kubernetes.io | INSTALL_K3S_EXEC="server --disable traefik --disable servicelb --disable-cloud-controller" sh -
EOT
  }
}

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

resource "oci_core_instance" "kubernetes_control_plane" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = oci_identity_compartment.kubernetes.id
  shape               = "VM.Standard.A1.Flex"
  display_name        = "kubernetes-control-plane"
  shape_config {
    memory_in_gbs = 8
    ocpus         = 2
  }
  source_details {
    source_id   = data.oci_core_images.kubernetes.images.0.id
    source_type = "image"
  }
  create_vnic_details {
    subnet_id        = oci_core_subnet.private.id
    assign_public_ip = false
    nsg_ids          = [oci_core_network_security_group.kubernetes.id]
  }
  # prevent the instance from destroying and recreating itself if the image ocid changes 
  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }
  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data           = data.cloudinit_config.kubernetes_control_plane.rendered
  }
}

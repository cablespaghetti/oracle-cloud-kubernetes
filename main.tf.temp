data "oci_core_images" "k3s" {
  compartment_id           = oci_identity_compartment.k3s.id
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_network_security_group" "k3s" {
  compartment_id = oci_identity_compartment.k3s.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "k3s"
}

resource "oci_core_network_security_group_security_rule" "k3s_ingress_ssh" {
  network_security_group_id = oci_core_network_security_group.k3s.id
  protocol                  = 6
  direction                 = "INGRESS"
  source                    = oci_core_network_security_group.bastion.id
  source_type               = "NETWORK_SECURITY_GROUP"
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "k3s_egress" {
  network_security_group_id = oci_core_network_security_group.k3s.id
  protocol                  = "all"
  direction                 = "EGRESS"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

data "template_cloudinit_config" "master" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "master.yaml"
    content_type = "text/cloud-config"
    content      = <<EOT
runcmd:
 - curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik --disable servicelb --disable-cloud-controller" sh -
EOT
  }
}

resource "oci_core_instance" "master" {
  availability_domain = "Eaff:UK-LONDON-1-AD-1"
  compartment_id      = oci_identity_compartment.k3s.id
  shape               = "VM.Standard.A1.Flex"
  display_name        = "k3s-master"
  shape_config {
    memory_in_gbs = 8
    ocpus         = 2
  }
  source_details {
    source_id   = data.oci_core_images.k3s.images.0.id
    source_type = "image"
  }
  create_vnic_details {
    subnet_id        = oci_core_subnet.private.id
    assign_public_ip = false
    nsg_ids          = [oci_core_network_security_group.k3s.id]
  }
  # prevent the instance from destroying and recreating itself if the image ocid changes 
  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }
  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = data.template_cloudinit_config.master.rendered
  }
}


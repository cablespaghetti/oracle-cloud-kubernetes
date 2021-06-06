data "oci_core_images" "bastion" {
  compartment_id           = oci_identity_compartment.k3s.id
  operating_system         = "Oracle Autonomous Linux"
  operating_system_version = "7.9"
  shape                    = "VM.Standard.E2.1.Micro"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_network_security_group" "bastion" {
  compartment_id = oci_identity_compartment.k3s.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "k3s-bastion"
}

resource "oci_core_network_security_group_security_rule" "bastion_ingress_ssh" {
  network_security_group_id = oci_core_network_security_group.bastion.id
  protocol                  = 6
  direction                 = "INGRESS"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "bastion_egress" {
  network_security_group_id = oci_core_network_security_group.bastion.id
  protocol                  = "all"
  direction                 = "EGRESS"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

resource "oci_core_instance" "bastion" {
  availability_domain = "Eaff:UK-LONDON-1-AD-1"
  compartment_id      = oci_identity_compartment.k3s.id
  shape               = "VM.Standard.E2.1.Micro"
  display_name        = "k3s-bastion"
  source_details {
    source_id   = data.oci_core_images.bastion.images.0.id
    source_type = "image"
  }
  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    nsg_ids          = [oci_core_network_security_group.bastion.id]
  }
  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
  # prevent the bastion from destroying and recreating itself if the image ocid changes 
  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }
}



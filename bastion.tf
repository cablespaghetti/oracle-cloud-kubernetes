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
    # Oracle-Linux-8.3-2021.05.12-0
    source_id   = "ocid1.image.oc1.uk-london-1.aaaaaaaa5muec6pf7r2kkrrt7hviq2pd4h2q4suet5mekcet756ba2ao2eta"
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



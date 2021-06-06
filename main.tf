variable "region" {
  default = "uk-london-1"
}

variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "ssh_public_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCcFIcpkymnv2XQ+mH6dUeVdc2Dt0kBNUweVdTxZw6xMNoa1Wsd7Ro0KgSStnDOO0xc6LvKIovj18QtlQ76D2xlyygxFjtS+q8FrjTeVnsJWl7DTrJXbIzFpP7LutcQ07qKSpL4FYslxTqwyoQs71SlLX2HkKWXHaeRbd/kAqZzRiwf2o/VRD5neNVqDSiOZbyMY7cYkMPtowk787xVUeyQQwzwRfQP1wXwvFwjhNtNe7JjnrPuJxTjTeCeHU1DV5FCt/T7CydyM6EAhrDECwf0rqJmyNs7Gq1Yf2QeMkTra7eM3oQxbjilkhUm1dXHs3pyzbjOMiPTTD2k42e14QEo1/tiJpvJq91jQ/d+zwUU9n/oApQ/FKyY1t0JRob3axEE7xeQfPgWNTDDVPCnP4YapXfOfPrvgRiDR1mZw9Y7fXifLZV0wgQcW/9NGM9NNPre6IG30ZrVBIW3SOIZViBH9xqyaHwubp+ANIKN8reFpntLMOCLv7/+ug3gom83JDU= samweston@Sams-Air.lan.cablespaghetti.dev"
}

provider "oci" {
  region           = var.region
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
}

terraform {
  required_providers {
    oci = {
      source = "hashicorp/oci"
    }
  }
  required_version = ">= 0.15"
}

resource "oci_identity_compartment" "k3s" {
  compartment_id = var.tenancy_ocid
  description    = "Compartment for Terraform resources."
  name           = "k3s"
}

module "vcn" {
  source                       = "oracle-terraform-modules/vcn/oci"
  version                      = "2.2.0"
  compartment_id               = oci_identity_compartment.k3s.id
  drg_display_name             = "gateway"
  internet_gateway_route_rules = []
  nat_gateway_route_rules      = []
  region                       = var.region
  vcn_dns_label                = "k3s"
  vcn_name                     = "k3s"
  nat_gateway_enabled          = true
  internet_gateway_enabled     = true
}

resource "oci_core_subnet" "private" {
  cidr_block                = "10.0.0.0/24"
  compartment_id            = oci_identity_compartment.k3s.id
  vcn_id                    = module.vcn.vcn_id
  display_name              = "private"
  dns_label                 = "private"
  prohibit_internet_ingress = true
  route_table_id            = module.vcn.nat_route_id
}

resource "oci_core_subnet" "public" {
  cidr_block     = "10.0.1.0/24"
  compartment_id = oci_identity_compartment.k3s.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "public"
  dns_label      = "public"
  route_table_id = module.vcn.ig_route_id
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
    # Oracle-Linux-8.3-aarch64-2021.05.12-0
    source_id   = "ocid1.image.oc1.uk-london-1.aaaaaaaay3vcesonkvlshlv2evtenhbsoyh5ovzwify4qfxc73uxlzy4dntq"
    source_type = "image"
  }
  create_vnic_details {
    subnet_id        = oci_core_subnet.private.id
    assign_public_ip = false
  }
  # prevent the bastion from destroying and recreating itself if the image ocid changes 
  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }
}

resource "oci_core_instance" "worker1" {
  availability_domain = "Eaff:UK-LONDON-1-AD-1"
  compartment_id      = oci_identity_compartment.k3s.id
  shape               = "VM.Standard.A1.Flex"
  display_name        = "k3s-worker1"
  shape_config {
    memory_in_gbs = 8
    ocpus         = 1
  }
  source_details {
    # Oracle-Linux-8.3-aarch64-2021.05.12-0
    source_id   = "ocid1.image.oc1.uk-london-1.aaaaaaaay3vcesonkvlshlv2evtenhbsoyh5ovzwify4qfxc73uxlzy4dntq"
    source_type = "image"
  }
  create_vnic_details {
    subnet_id        = oci_core_subnet.private.id
    assign_public_ip = false
  }
  # prevent the bastion from destroying and recreating itself if the image ocid changes 
  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }
}

resource "oci_core_instance" "worker2" {
  availability_domain = "Eaff:UK-LONDON-1-AD-1"
  compartment_id      = oci_identity_compartment.k3s.id
  shape               = "VM.Standard.A1.Flex"
  display_name        = "k3s-worker2"
  shape_config {
    memory_in_gbs = 8
    ocpus         = 1
  }
  source_details {
    # Oracle-Linux-8.3-aarch64-2021.05.12-0
    source_id   = "ocid1.image.oc1.uk-london-1.aaaaaaaay3vcesonkvlshlv2evtenhbsoyh5ovzwify4qfxc73uxlzy4dntq"
    source_type = "image"
  }
  create_vnic_details {
    subnet_id        = oci_core_subnet.private.id
    assign_public_ip = false
  }
  # prevent the bastion from destroying and recreating itself if the image ocid changes 
  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }
}

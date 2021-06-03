variable "region" {
  default = "uk-london-1"
}

variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}

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

resource "oci_bastion_bastion" "bastion" {
  bastion_type                 = "standard"
  compartment_id               = oci_identity_compartment.k3s.id
  target_subnet_id             = oci_core_subnet.private.id
  client_cidr_block_allow_list = ["0.0.0.0/0"]
}

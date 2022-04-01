locals {
  vcn_cidr     = "${var.cidr_block}/16"
  private_cidr = cidrsubnet(local.vcn_cidr, 2, 0)
  public_cidr  = cidrsubnet(local.vcn_cidr, 2, 1)
  bastion_cidr = cidrsubnet(local.vcn_cidr, 8, 254)
}

resource "oci_identity_compartment" "kubernetes" {
  compartment_id = var.tenancy_ocid
  description    = "Compartment for Terraform resources."
  name           = var.compartment_name
  enable_delete  = true
}

module "vcn" {
  source                  = "oracle-terraform-modules/vcn/oci"
  version                 = "3.4.0"
  compartment_id          = oci_identity_compartment.kubernetes.id
  drg_display_name        = "gateway"
  region                  = var.region
  vcn_dns_label           = "kubernetes"
  vcn_name                = "kubernetes"
  create_nat_gateway      = true
  create_internet_gateway = true
  vcn_cidrs               = [local.vcn_cidr]
}

resource "oci_core_subnet" "private" {
  cidr_block                = local.private_cidr
  compartment_id            = oci_identity_compartment.kubernetes.id
  vcn_id                    = module.vcn.vcn_id
  display_name              = "private"
  dns_label                 = "private"
  prohibit_internet_ingress = true
  route_table_id            = module.vcn.nat_route_id
}

resource "oci_core_subnet" "public" {
  cidr_block     = local.public_cidr
  compartment_id = oci_identity_compartment.kubernetes.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "public"
  dns_label      = "public"
  route_table_id = module.vcn.ig_route_id
}

module "bastion" {
  source              = "oracle-terraform-modules/bastion/oci"
  version             = "3.1.0"
  compartment_id      = oci_identity_compartment.kubernetes.id
  tenancy_id          = var.tenancy_ocid
  ig_route_id         = module.vcn.ig_route_id
  vcn_id              = module.vcn.vcn_id
  bastion_shape       = { "shape" : "VM.Standard.E2.1.Micro" }
  bastion_timezone    = "UTC"
  ssh_public_key_path = var.ssh_public_key_path
  netnum              = 254
  newbits             = 8
  providers = {
    oci.home = oci
  }
}

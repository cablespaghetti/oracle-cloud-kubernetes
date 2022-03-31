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
  vcn_cidrs               = ["10.200.0.0/16"]
}

#resource "oci_core_security_list" "private" {
#  compartment_id = oci_identity_compartment.k3s.id
#  vcn_id         = module.vcn.vcn_id
#}

resource "oci_core_subnet" "private" {
  cidr_block                = "10.200.0.0/18"
  compartment_id            = oci_identity_compartment.kubernetes.id
  vcn_id                    = module.vcn.vcn_id
  display_name              = "private"
  dns_label                 = "private"
  prohibit_internet_ingress = true
  route_table_id            = module.vcn.nat_route_id
  #security_list_ids         = [oci_core_security_list.private.id]
}

#resource "oci_core_security_list" "public" {
#  compartment_id = oci_identity_compartment.k3s.id
#  vcn_id         = module.vcn.vcn_id
#}

resource "oci_core_subnet" "public" {
  cidr_block     = "10.200.64.0/18"
  compartment_id = oci_identity_compartment.kubernetes.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "public"
  dns_label      = "public"
  route_table_id = module.vcn.ig_route_id
  #security_list_ids = [oci_core_security_list.public.id]
}


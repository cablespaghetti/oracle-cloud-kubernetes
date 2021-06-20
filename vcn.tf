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

resource "oci_core_security_list" "private" {
  compartment_id = oci_identity_compartment.k3s.id
  vcn_id         = module.vcn.vcn_id
}

resource "oci_core_subnet" "private" {
  cidr_block                = "10.0.0.0/24"
  compartment_id            = oci_identity_compartment.k3s.id
  vcn_id                    = module.vcn.vcn_id
  display_name              = "private"
  dns_label                 = "private"
  prohibit_internet_ingress = true
  route_table_id            = module.vcn.nat_route_id
  security_list_ids         = [oci_core_security_list.private.id]
}

resource "oci_core_security_list" "public" {
  compartment_id = oci_identity_compartment.k3s.id
  vcn_id         = module.vcn.vcn_id
}

resource "oci_core_subnet" "public" {
  cidr_block        = "10.0.10.0/24"
  compartment_id    = oci_identity_compartment.k3s.id
  vcn_id            = module.vcn.vcn_id
  display_name      = "public"
  dns_label         = "public"
  route_table_id    = module.vcn.ig_route_id
  security_list_ids = [oci_core_security_list.public.id]
}


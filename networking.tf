module "vcn" {
  source                  = "oracle-terraform-modules/vcn/oci"
  version                 = "3.4.0"
  compartment_id          = oci_identity_compartment.kubernetes.id
  drg_display_name        = "gateway"
  region                  = var.region
  vcn_dns_label           = var.environment_name
  vcn_name                = var.environment_name
  create_nat_gateway      = true
  create_internet_gateway = true
  vcn_cidrs               = [local.vcn_cidr]
  freeform_tags           = local.freeform_tags
}

# Security list to allow Oracle Managed Bastion SSH access
resource "oci_core_security_list" "private" {
  compartment_id = oci_identity_compartment.kubernetes.id
  vcn_id         = module.vcn.vcn_id
  freeform_tags  = local.freeform_tags

  display_name = "${var.environment_name}-private"
  egress_security_rules {
    destination      = local.private_cidr
    protocol         = 6
    description      = "SSH within private subnet"
    destination_type = "CIDR_BLOCK"
    tcp_options {
      max = 22
      min = 22
    }
  }
}

resource "oci_core_subnet" "private" {
  cidr_block                = local.private_cidr
  compartment_id            = oci_identity_compartment.kubernetes.id
  vcn_id                    = module.vcn.vcn_id
  display_name              = "private"
  dns_label                 = "private"
  prohibit_internet_ingress = true
  route_table_id            = module.vcn.nat_route_id
  security_list_ids         = [oci_core_security_list.private.id]
  freeform_tags             = local.freeform_tags
}

resource "oci_core_subnet" "public" {
  cidr_block     = local.public_cidr
  compartment_id = oci_identity_compartment.kubernetes.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "public"
  dns_label      = "public"
  route_table_id = module.vcn.ig_route_id
  freeform_tags  = local.freeform_tags
}


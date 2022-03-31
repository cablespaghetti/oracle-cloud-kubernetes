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

output "bastion_ip" {
  value = oci_core_instance.bastion.public_ip
}

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

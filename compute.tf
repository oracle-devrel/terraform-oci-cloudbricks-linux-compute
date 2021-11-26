# Copyright (c) 2021 Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# compute.tf
#
# Purpose: The following script defines the creation of compute instances based on an image available within the region
# Registry: https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_instance
#           https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_volume_backup_policy_assignment 



resource "oci_core_instance" "Compute" {

  count               = var.num_instances
  availability_domain = var.compute_availability_domain_list[count.index % length(var.compute_availability_domain_list)]
  compartment_id      = local.compartment_id
  display_name        = count.index < "9" ? "${var.compute_display_name_base}${var.label_zs[0]}${count.index + 1}" : "${var.compute_display_name_base}${var.label_zs[1]}${count.index + 1}"
  shape               = var.instance_shape
  fault_domain        = var.fault_domain_name[count.index % length(var.fault_domain_name)]

  agent_config {
    plugins_config {
      desired_state = "ENABLED"
      name = "Bastion"
    }
  }

  dynamic "create_vnic_details" {
    for_each = var.is_nsg_required ? [1] : []
    content {
      subnet_id        = local.subnet_ocid
      display_name     = var.primary_vnic_display_name
      assign_public_ip = var.assign_public_ip_flag
      hostname_label   = count.index < "9" ? "${var.compute_display_name_base}${var.label_zs[0]}${count.index + 1}" : "${var.compute_display_name_base}${var.label_zs[1]}${count.index + 1}"
      private_ip       = var.private_ip
      nsg_ids          = [local.nsg_id]
    }
  }

  dynamic "create_vnic_details" {
    for_each = var.is_nsg_required ? [] : [1]
    content {
      subnet_id        = local.subnet_ocid
      display_name     = var.primary_vnic_display_name
      assign_public_ip = var.assign_public_ip_flag
      hostname_label   = count.index < "9" ? "${var.compute_display_name_base}${var.label_zs[0]}${count.index + 1}" : "${var.compute_display_name_base}${var.label_zs[1]}${count.index + 1}"
      private_ip       = var.private_ip
    }
  }

  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid
  }

  connection {
    type        = "ssh"
    host        = self.private_ip
    user        = "opc"
    private_key = var.ssh_private_is_path ? file(var.ssh_private_key) : var.ssh_private_key
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_is_path ? file(var.ssh_public_key) : var.ssh_public_key
  }

  timeouts {
    create = "15m"
  }

  dynamic "shape_config" {
    for_each = var.is_flex_shape ? [1] : []
    content {
      memory_in_gbs = var.instance_shape_config_memory_in_gbs
      ocpus         = var.instance_shape_config_ocpus
    }
  }
}


resource "oci_core_volume_backup_policy_assignment" "backup_policy_assignment_BootVolume" {
  count     = var.num_instances
  asset_id  = oci_core_instance.Compute[count.index].boot_volume_id
  policy_id = local.backup_policy_bootvolume_disk_id
}
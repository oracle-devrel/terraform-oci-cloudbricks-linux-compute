# Copyright (c) 2021 Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# output.tf
#
# Purpose: The following file defines the output for linux_compute brick


output "server_display_name" {
  description = "Compute Display Name"
  value       = oci_core_instance.Compute.*.display_name
}

output "instance_private_ip" {
  description = "Compute Private IP"
  value       = oci_core_instance.Compute.*.private_ip
}

output "instance" {
  description = "Compute Generated"
  value       = oci_core_instance.Compute
}
output "vpc_lattice_service_endpoint" {
  value = var.enable_vpc_lattice_service_demo ? aws_vpclattice_service.hello_world[0].dns_entry[0].domain_name : ""
}
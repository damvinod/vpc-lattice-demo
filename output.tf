output "vpc_lattice_service_endpoint" {
  value = aws_vpclattice_service.hello_world.dns_entry[0].domain_name
}
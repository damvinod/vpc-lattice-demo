variable "team_name" {
  description = "Required variable used for tagging, naming and isolating teams"
  default     = "merlion"
}

variable "environment" {
  description = "Required variable for isolating environments"
  default     = "dev"
}

variable "enable_vpc_lattice_service_demo" {
  type        = bool
  default     = false
  description = "This feature toggle demonstrates Lattice Service features"
}

variable "enable_vpc_lattice_rds_resource_gw_demo" {
  type        = bool
  default     = false
  description = "This feature toggle demonstrates Lattice Resource Gateway with RDS feature."
}

variable "enable_service_connect_demo" {
  type        = bool
  default     = false
  description = "This feature toggle demonstrates service_connect feature by deploying hello-world-v1-svc in same subnet as demo-svc. To showcase the connectivity between these 2 services."
}
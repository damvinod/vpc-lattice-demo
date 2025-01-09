variable "team_name" {
  description = "Required variable used for tagging, naming and isolating teams"
  default = "merlion"
}

variable "environment" {
  description = "Required variable for isolating environments"
  default = "dev"
}

variable "create_rds" {
  type = bool
  default = false
}
variable "transit_gw_name" {
  type = string
}

variable "vpcs" {
  type = map(object({
    vpc_id                  = string
    cidr_block              = string
    private_subnet_ids      = list(string)
    private_route_table_ids = list(string)
  }))
}

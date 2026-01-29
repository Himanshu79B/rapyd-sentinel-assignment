locals {
  tgw_routes = {
    for route in flatten([
      for src_vpc, src_config in var.vpcs : [
        for dst_vpc, dst_config in var.vpcs : [
          for route_table_id in src_config.private_route_table_ids : {
            key                    = "${src_vpc}-${dst_vpc}-${route_table_id}"
            route_table_id         = route_table_id
            destination_cidr_block = dst_config.cidr_block
          }
          if src_vpc != dst_vpc
        ]
      ]
    ]) : route.key => route
  }
}

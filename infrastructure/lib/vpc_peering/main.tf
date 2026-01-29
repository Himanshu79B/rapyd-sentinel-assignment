resource "aws_ec2_transit_gateway" "hub" {
  description = var.transit_gw_name

  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = {
    Name = var.transit_gw_name
  }
}

resource "aws_ec2_transit_gateway_route_table" "hub" {
  transit_gateway_id = aws_ec2_transit_gateway.hub.id

  tags = {
    Name = var.transit_gw_name
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc" {
  for_each = var.vpcs

  transit_gateway_id = aws_ec2_transit_gateway.hub.id
  vpc_id             = each.value.vpc_id
  subnet_ids         = each.value.private_subnet_ids

  tags = {
    Name = "tgw-${var.transit_gw_name}-vpc-${each.key}-att"
  }
}

# Association
resource "aws_ec2_transit_gateway_route_table_association" "vpc" {
  for_each = aws_ec2_transit_gateway_vpc_attachment.vpc

  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
  transit_gateway_attachment_id  = each.value.id
}

# propagation
resource "aws_ec2_transit_gateway_route_table_propagation" "vpc" {
  for_each = aws_ec2_transit_gateway_vpc_attachment.vpc

  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
  transit_gateway_attachment_id  = each.value.id
}

resource "aws_route" "vpc_peering_tgw" {
  for_each = local.tgw_routes

  transit_gateway_id     = aws_ec2_transit_gateway.hub.id
  route_table_id         = each.value.route_table_id
  destination_cidr_block = each.value.destination_cidr_block
}

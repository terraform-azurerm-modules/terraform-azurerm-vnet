data "azurerm_client_config" "current" {}

locals {
  // Avoid lists of maps as for_each want either sets or maps
  // And dynamic maps using for x in y cause errors in nested modules
  // Convert into a map of maps
  service_endpoints = {
    for subnet in keys(var.service_endpoints) :
    subnet => [
      for service in var.service_endpoints[subnet] :
      "Microsoft.${trimprefix(service, "Microsoft.")}"
    ]
  }

  // Only one DDOS Protection Plan per region
  ddos_vnet = toset(var.ddos ? ["Standard"] : [])

  // Create arrays for peering
  hub_vnet = length(var.hub_vnet_id) == 0 ? {} : {
      resource_group_name  = split("/", var.hub_vnet_id)[4]
      vnet_name            = split("/", var.hub_vnet_id)[8]
      id                   = var.hub_vnet_id
  }

  spoke_to_hub = toset(length(var.hub_vnet_id) > 0 ? ["${var.vnet_name}_to_${local.hub_vnet.vnet_name}"] : [])
  hub_to_spoke = toset(length(var.hub_vnet_id) > 0 ? ["${local.hub_vnet.vnet_name}_to_${var.vnet_name}"] : [])

  vpngw = toset(length(var.vpngw_name) > 0 ? [var.vpngw_name]: [])

}

resource "azurerm_network_ddos_protection_plan" "ddos" {
  for_each = local.ddos_vnet
  name     = each.value

  resource_group_name = var.resource_group
  location            = var.location
  tags                = var.tags

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.resource_group
  location            = var.location
  tags                = var.tags
  depends_on          = [var.module_depends_on]

  address_space = var.address_space
  dns_servers   = var.dns_servers

  dynamic "ddos_protection_plan" {
    for_each = local.ddos_vnet
    content {
      id     = azurerm_network_ddos_protection_plan.ddos[ddos_protection_plan.value].id
      enable = true
    }
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_subnet" "subnet" {
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.vnet.name

  for_each = var.subnets

  name              = each.key
  address_prefix    = each.value
  service_endpoints = contains(keys(local.service_endpoints), each.key) ? local.service_endpoints[each.key] : null
}

resource "azurerm_subnet_network_security_group_association" "subnet" {
  for_each = var.nsgs

  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = each.value
}

//  spoke_to_hub = length(var.hub_vnet_name) ? [ "${var.vnet_name}_to_${var.hub_vnet_name}" ] : []
//  hub_to_spoke = length(var.hub_vnet_name) ? [ "${var.hub_vnet_name}_to_${var.vnet_name}" ] : []

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each                  = local.spoke_to_hub

  name                      = each.value
  resource_group_name       = azurerm_virtual_network.vnet.resource_group_name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = local.hub_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = true
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each                  = local.hub_to_spoke

  name                      = each.value
  resource_group_name       = local.hub_vnet.resource_group_name
  virtual_network_name      = local.hub_vnet.vnet_name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

resource "azurerm_public_ip" "vpngw" {
  for_each            = local.vpngw

  name                = each.value
  resource_group_name = var.resource_group
  location            = var.location
  tags                = var.tags

  allocation_method = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "vpn" {
  for_each            = local.vpngw

  name                = each.value
  resource_group_name = var.resource_group
  location            = var.location
  tags                = var.tags

  type       = "Vpn"
  vpn_type   = var.vpngw_sku == "Basic" ? "PolicyBased" : "RouteBased"
  enable_bgp = var.vpngw_sku == "Basic" ? false : var.vpngw_bgp
  sku        = var.vpngw_sku
  generation = var.vpngw_sku == "Basic" || var.vpngw_sku == "VpnGw1" ? "Generation1" : "Generation2"

  ip_configuration {
    name                          = "vpngwIpConfig"
    public_ip_address_id          = azurerm_public_ip.vpngw[each.value].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.subnet["GatewaySubnet"].id
  }
}
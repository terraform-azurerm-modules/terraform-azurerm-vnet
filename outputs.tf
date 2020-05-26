output "vnet" {
  value = {
    id              = azurerm_virtual_network.vnet.id
    subscription_id = data.azurerm_client_config.current.subscription_id
    resource_group  = azurerm_virtual_network.vnet.resource_group_name // azurerm_virtual_network.vnet.resource_group
    name            = azurerm_virtual_network.vnet.name                // var.vnet_name
    address_space   = azurerm_virtual_network.vnet.address_space
    dns             = azurerm_virtual_network.vnet.dns_servers
    ddos            = var.ddos ? azurerm_network_ddos_protection_plan.ddos["Standard"].id : null
  }

  /* Type constraint for use with variable definitions

    vnet = object({
      id                = string
      subscription_id   = string
      resource_group    = string
      name              = string
      address_space     = list(string)
      dns               = list(string)
    })
  */
}

output "subnets" {
  value = {
    for subnet, address_prefix in var.subnets :
    subnet => {
      name              = subnet
      id                = azurerm_subnet.subnet[subnet].id
      address_prefix    = address_prefix
      nsg_id            = contains(keys(var.nsgs), subnet) ? var.nsgs[subnet] : ""
      service_endpoints = contains(keys(var.service_endpoints), subnet) ? var.service_endpoints[subnet] : []
    }
  }

  /* Type constraint cannot be used for whole map as it has unknown keys
     For each individual subnet object:

    subnet = object({
      name              = string
      id                = string
      address_prefix    = string
      nsg_id            = string
      service_endpoints = list(string)
    })
  */
}

output "hub_vnet" {
  value = local.hub_vnet
}
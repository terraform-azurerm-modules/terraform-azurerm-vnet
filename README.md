# terraform-azurerm-vnet

***Note that this repo may be deprecated as it does not give much more than the standard azurerm providers.***

## Description

This Terraform module deploys a vNet with any number of subnets.

You can also:

* assign custom DNS servers
* use the standard DDOS protection plan (see [pricing](https://azure.microsoft.com/pricing/details/ddos-protection/))

* associate Network Security Groups (NSGs) to subnets
* add service endpoints to subnets

* specify a hub vNet resourceId to peer as a spoke vNet
* specify a default route IP address to configure a Route Table associated with all subnets

> If you are overriding the system routing tables with more complex configurations then please use the native [azurerm_route](https://www.terraform.io/docs/providers/azurerm/r/route.html), [azurerm_route_table](https://www.terraform.io/docs/providers/azurerm/r/route_table.html) and [azurerm_subnet_route_table_association](https://www.terraform.io/docs/providers/azurerm/r/subnet_route_table_association.html) resource types.

## Usage

### Simple Hub Example

```terraform
provider "azurerm" {
  version = "~> 2.11.0"
  features {}
}

resource "azurerm_resource_group" "test" {
  name     = "myTestResourceGroup"
  location = "West Europe"

  tags     = {
    environment = "dev"
    costcenter  = "it"
  }
}

module "network" {
  source                 = "github.com/terraform-azurerm-modules/terraform-azure-vnet"
  resource_group         = azurerm_resource_group.test.name
  location               = azurerm_resource_group.test.location
  tags                   = azurerm_resource_group.test.tags

  vnet_name              = "hub"
  address_space          = [ "10.0.0.0/24" ]
  dns_servers            = [ "10.0.0.68", "10.0.0.69" ]

  subnets                = {
    AzureFirewallSubnet  = "10.0.0.0/26"
    SharedServices       = "10.0.0.64/26"
    AzureBastionSubnet   = "10.0.0.192/27"
    GatewaySubnet        = "10.0.0.224/27"
  }
}

output "vnet" {
  value       = module.network.vnet
  description = "The module's vnet object."
}

output "subnets" {
  value       = module.network.subnets
  description = "The module's subnets object."
}
```

## Authors

Originally created by [Richard Cheney](http://github.com/richeney)

## License

[MIT](LICENSE)

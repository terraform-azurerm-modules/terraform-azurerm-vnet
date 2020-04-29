variable "resource_group" {
  type = string
  description = "Name of an existing resource group to deply the virtual network into."
}

variable "location" {
  type    = string
  description = "The Azure region to deploy to. Recommendation is to set to the same location as the resource group."
  default = ""
}

variable "vnet_name" {
  type = string
  description = "Name of the virtual network (vNet) to create."
}

variable "address_space" {
  type    = list(string)
  description = "Array containing the IPv4 address space for the virtual network in. Default is [\"10.0.0.0/16\"]."
  default = ["10.0.0.0/16"]
}

variable "dns_servers" {
  type    = list(string)
  description = "Array of IP addresses for custom DNS servers. Default: none, i.e. use Azure DNS."
  default = null
}

variable "ddos" {
  type    = bool
  description = "Boolean to deploy [Azure DDOS Protection](https://azure.microsoft.com/services/ddos-protection/). Default: false."
  default = false
}

variable "hub_id" {
  type        = string
  description = "Resource ID for hub vnet. Triggers standard hub and spoke peer. Default: none."
  default     = ""
}

variable "default_route" {
  type    = string
  description = "Override the default route. Set to hub vNet's Azure Firewall or NVA internal IP address."
  default = null
}

variable "subnets" {
  type = map(string)
  description = "Map of subnet names to address prefixes. Default: none."
  default = {}
}

variable "nsgs" {
  type = map(string)
  description = "Map of subnet names to network security group IDs (nsg_ids). Default: none."
  default = {}
}

variable "service_endpoints" {
  type        = map(list(string))
  description = "Map of subnet names to a list of Azure [Service Tags](https://docs.microsoft.com/azure/virtual-network/service-tags-overview). Default: none."
  // example = "{ <subnet_name>: [ \"AzureService\" ]} from AzureActiveDirectory, AzureCosmosDB, ContainerRegistry, EventHub, KeyVault, ServiceBus, Sql, Storage and Web."
  default     = {}
}

variable "tags" {
  type    = map
  description = "Map of key value pairs for the resource tagging. Default: none."
  default = {}
}

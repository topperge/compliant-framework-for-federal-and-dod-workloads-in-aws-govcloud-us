################################################################################
# Feature flags (written to SSM by transit-init from config.json)
################################################################################

variable "enable_virtual_firewall" {
  description = "Deploy the virtual-firewall (firewall VPC + VPN) routing. SSM: /compliant/framework/transit/virtual-firewall/enabled"
  type        = bool
  default     = true
}

variable "enable_vpc_firewall" {
  description = "Deploy the VPC-firewall (DMZ + inspection VPC) routing. When true the vpc-firewall family is used for the internal/management-services/directory/external-access route tables, otherwise the virtual-firewall family. SSM: /compliant/framework/transit/vpc-firewall/enabled"
  type        = bool
  default     = false
}

variable "enable_directory_vpc" {
  description = "Directory VPC is deployed in management services. SSM: /compliant/framework/transit/directory-vpc/enabled"
  type        = bool
  default     = true
}

variable "enable_external_access_vpc" {
  description = "External access VPC is deployed in management services. SSM: /compliant/framework/transit/external-access-vpc/enabled"
  type        = bool
  default     = true
}

variable "attach_firewall_vpc" {
  description = "The (virtual) firewall VPC is attached to the transit gateway; controls the 0.0.0.0/0 routes / propagations / association to the firewall VPC attachment (virtual-firewall family only). SSM: /compliant/framework/transit/firewall-vpc/tgw/attached"
  type        = bool
  default     = true
}

################################################################################
# Transit gateway route table ids (transit-gateway module outputs)
################################################################################

variable "internal_route_table_id" {
  description = "Internal TGW route table id. SSM: /compliant/framework/transit/transit-gateway/internal-route-table/id"
  type        = string
}

variable "management_services_route_table_id" {
  description = "Management services TGW route table id. SSM: /compliant/framework/transit/transit-gateway/management-services-route-table/id"
  type        = string
}

variable "directory_route_table_id" {
  description = "Directory TGW route table id (required when enable_directory_vpc). SSM: /compliant/framework/transit/transit-gateway/directory-route-table/id"
  type        = string
  default     = null
}

variable "external_access_route_table_id" {
  description = "External access TGW route table id (required when enable_external_access_vpc). SSM: /compliant/framework/transit/transit-gateway/external-access-route-table/id"
  type        = string
  default     = null
}

variable "firewall_route_table_id" {
  description = "Firewall TGW route table id (required when enable_virtual_firewall). SSM: /compliant/framework/transit/transit-gateway/firewall-route-table/id"
  type        = string
  default     = null
}

variable "dmz_route_table_id" {
  description = "DMZ TGW route table id (required when enable_vpc_firewall). SSM: /compliant/framework/transit/transit-gateway/dmz-route-table/id"
  type        = string
  default     = null
}

variable "inspection_route_table_id" {
  description = "Inspection TGW route table id (required when enable_vpc_firewall). SSM: /compliant/framework/transit/transit-gateway/inspection-route-table/id"
  type        = string
  default     = null
}

################################################################################
# Transit gateway attachment ids
################################################################################

variable "management_services_vpc_tgw_attachment_id" {
  description = "TGW attachment id of the management services VPC (management-services-init output oManagementServicesVpcTransitGatewayAttachmentId)."
  type        = string
}

variable "directory_vpc_tgw_attachment_id" {
  description = "TGW attachment id of the directory VPC (management-services-init output oDirectoryVpcTransitGatewayAttachmentId). Required when enable_directory_vpc."
  type        = string
  default     = null
}

variable "external_access_vpc_tgw_attachment_id" {
  description = "TGW attachment id of the external access VPC (management-services-init output oExternalAccessVpcTransitGatewayAttachmentId). Required when enable_external_access_vpc."
  type        = string
  default     = null
}

variable "firewall_vpc_tgw_attachment_id" {
  description = "TGW attachment id of the virtual firewall VPC. Required when the virtual-firewall family is used (or enable_virtual_firewall) and attach_firewall_vpc. SSM: /compliant/framework/transit/firewall-vpc/tgw-attach/id"
  type        = string
  default     = null
}

variable "inspection_vpc_tgw_attachment_id" {
  description = "TGW attachment id of the inspection VPC. Required when enable_vpc_firewall. SSM: /compliant/framework/transit/inspection-vpc/tgw-attach/id"
  type        = string
  default     = null
}

variable "dmz_vpc_tgw_attachment_id" {
  description = "TGW attachment id of the DMZ VPC. Required when enable_vpc_firewall. SSM: /compliant/framework/transit/dmz-vpc/tgw-attach/id"
  type        = string
  default     = null
}

variable "tags" {
  description = "Accepted for interface consistency; TGW route table associations/propagations/routes are not taggable."
  type        = map(string)
  default     = {}
}

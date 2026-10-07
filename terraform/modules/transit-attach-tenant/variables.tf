variable "tgw_attachment_id" {
  description = "Transit gateway attachment id of the tenant / plugin VPC (CFN pTgwAttachId; tenant VPC output oTransitGatewayAttachmentId, SSM /compliant/framework/tenant/<prefix>/vpc/tgw-attachment/id in the tenant account)."
  type        = string
}

################################################################################
# Feature flags (written to SSM by transit-init from config.json)
################################################################################

variable "enable_virtual_firewall" {
  description = "Propagate the tenant attachment into the firewall route table. SSM: /compliant/framework/transit/virtual-firewall/enabled"
  type        = bool
  default     = true
}

variable "enable_vpc_firewall" {
  description = "Propagate the tenant attachment into the inspection route table. SSM: /compliant/framework/transit/vpc-firewall/enabled"
  type        = bool
  default     = false
}

variable "enable_directory_vpc" {
  description = "Propagate the tenant attachment into the directory route table. SSM: /compliant/framework/transit/directory-vpc/enabled"
  type        = bool
  default     = true
}

variable "enable_external_access_vpc" {
  description = "Propagate the tenant attachment into the external access route table. SSM: /compliant/framework/transit/external-access-vpc/enabled"
  type        = bool
  default     = true
}

################################################################################
# Transit gateway route table ids (transit-gateway module outputs)
################################################################################

variable "internal_route_table_id" {
  description = "Internal TGW route table id (the tenant attachment is associated with it). SSM: /compliant/framework/transit/transit-gateway/internal-route-table/id"
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

variable "firewall_route_table_id" {
  description = "Firewall TGW route table id (required when enable_virtual_firewall). SSM: /compliant/framework/transit/transit-gateway/firewall-route-table/id"
  type        = string
  default     = null
}

variable "inspection_route_table_id" {
  description = "Inspection TGW route table id (required when enable_vpc_firewall). SSM: /compliant/framework/transit/transit-gateway/inspection-route-table/id"
  type        = string
  default     = null
}

variable "external_access_route_table_id" {
  description = "External access TGW route table id (required when enable_external_access_vpc). SSM: /compliant/framework/transit/transit-gateway/external-access-route-table/id"
  type        = string
  default     = null
}

variable "tags" {
  description = "Accepted for interface consistency; TGW route table associations/propagations are not taggable."
  type        = map(string)
  default     = {}
}

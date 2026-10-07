variable "transit_gateway_amazon_side_asn" {
  description = "Private ASN for the Amazon side of the BGP session (SSM: /compliant/framework/transit/transit-gateway/amazon-side-asn)."
  type        = number
  default     = 65224
}

variable "central_account_id" {
  description = "Account id of the central (organization management) account; used to build the organization ARN for the RAM share."
  type        = string
}

variable "principal_org_id" {
  description = "AWS Organizations id (o-xxxxxxxxxx) the transit gateway is shared with."
  type        = string
}

variable "enable_directory_vpc" {
  description = "Create the directory (AD/DNS) TGW route table."
  type        = bool
  default     = false
}

variable "enable_external_access_vpc" {
  description = "Create the external-access (OOB) TGW route table."
  type        = bool
  default     = false
}

variable "enable_vpc_firewall" {
  description = "Create the DMZ and inspection TGW route tables (AWS Network Firewall / VPC firewall design)."
  type        = bool
  default     = false
}

variable "enable_virtual_firewall" {
  description = "Create the firewall TGW route table (virtual firewall / VDSS design)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}

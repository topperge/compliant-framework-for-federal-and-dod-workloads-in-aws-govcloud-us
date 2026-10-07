variable "name" {
  description = "Name prefix for resources (pName). transit-init.yml passes \"firewall\"."
  type        = string
  default     = "firewall"
}

variable "transit_gateway_id" {
  description = "Transit gateway id the VPN connections terminate on (output of the transit-gateway module)."
  type        = string
}

variable "customer_gateway_a_ip_address" {
  description = "Public IP of customer gateway A (transit-firewall-vpc output firewall_a_internal_eni_public_ip_address)."
  type        = string
}

variable "customer_gateway_b_ip_address" {
  description = "Public IP of customer gateway B (transit-firewall-vpc output firewall_b_internal_eni_public_ip_address)."
  type        = string
}

variable "customer_gateway_a_bgp_asn" {
  description = "BGP ASN of virtual firewall A (SSM: /compliant/framework/transit/firewall-vpc/virtual-firewall/a/asn)."
  type        = string
  default     = "65200"
}

variable "customer_gateway_b_bgp_asn" {
  description = "BGP ASN of virtual firewall B (SSM: /compliant/framework/transit/firewall-vpc/virtual-firewall/b/asn)."
  type        = string
  default     = "65210"
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}

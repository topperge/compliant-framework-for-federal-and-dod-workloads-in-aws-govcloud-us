variable "name" {
  description = "Name prefix for resources (pName). transit-init.yml passes \"firewall\"."
  type        = string
  default     = "firewall"
}

variable "transit_gateway_id" {
  description = "Transit gateway id to attach the VPC to (output of the transit-gateway module)."
  type        = string
}

variable "logging_bucket_arn" {
  description = "ARN of the S3 bucket receiving VPC flow logs (transit-init.yml: arn:<partition>:s3:::flow-logs-<management-services-account-id>-<region>)."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR (SSM: /compliant/framework/transit/firewall-vpc/cidr)."
  type        = string
  default     = "10.0.0.0/21"
}

variable "vpc_nipr_cidr" {
  description = "Secondary NIPR CIDR associated with the VPC; \"0.0.0.0/0\" means none (SSM: /compliant/framework/transit/firewall-vpc/nipr-cidr)."
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_tenancy" {
  description = "VPC instance tenancy (SSM: /compliant/framework/transit/firewall-vpc/instance-tenancy)."
  type        = string
  default     = "default"
}

variable "enable_igw" {
  description = "Create an internet gateway, NAT gateways and default routes (SSM: /compliant/framework/transit/firewall-vpc/igw/enabled)."
  type        = bool
  default     = true
}

variable "attach_tgw" {
  description = "Attach the VPC to the transit gateway and route RFC1918 to it (SSM: /compliant/framework/transit/firewall-vpc/tgw/attached)."
  type        = bool
  default     = true
}

variable "external_subnet_a_cidr" {
  description = "External subnet A CIDR (SSM: /compliant/framework/transit/firewall-vpc/external-subnet/a/cidr)."
  type        = string
  default     = "10.0.0.0/24"
}

variable "external_subnet_b_cidr" {
  description = "External subnet B CIDR (SSM: /compliant/framework/transit/firewall-vpc/external-subnet/b/cidr)."
  type        = string
  default     = "10.0.1.0/24"
}

variable "internal_subnet_a_cidr" {
  description = "Internal subnet A CIDR (SSM: /compliant/framework/transit/firewall-vpc/internal-subnet/a/cidr)."
  type        = string
  default     = "10.0.3.0/24"
}

variable "internal_subnet_b_cidr" {
  description = "Internal subnet B CIDR (SSM: /compliant/framework/transit/firewall-vpc/internal-subnet/b/cidr)."
  type        = string
  default     = "10.0.4.0/24"
}

variable "management_subnet_a_cidr" {
  description = "Management subnet A CIDR (SSM: /compliant/framework/transit/firewall-vpc/management-subnet/a/cidr)."
  type        = string
  default     = "10.0.6.0/27"
}

variable "management_subnet_b_cidr" {
  description = "Management subnet B CIDR (SSM: /compliant/framework/transit/firewall-vpc/management-subnet/b/cidr)."
  type        = string
  default     = "10.0.6.32/27"
}

variable "transit_gateway_attachment_subnet_a_cidr" {
  description = "TGW attachment subnet A CIDR (SSM: /compliant/framework/transit/firewall-vpc/tgw-attach-subnet/a/cidr)."
  type        = string
  default     = "10.0.7.208/28"
}

variable "transit_gateway_attachment_subnet_b_cidr" {
  description = "TGW attachment subnet B CIDR (SSM: /compliant/framework/transit/firewall-vpc/tgw-attach-subnet/b/cidr)."
  type        = string
  default     = "10.0.7.224/28"
}

variable "flow_log_group_name" {
  description = "Name of the flow-log CloudWatch log group. CFN let CloudFormation generate it; set this to the existing name when importing. Null = generated from name_prefix \"<name>-vpc-flow-logs-\"."
  type        = string
  default     = null
}

variable "flow_log_role_name" {
  description = "Name of the flow-log IAM role. CFN let CloudFormation generate it; set this to the existing name when importing. Null = generated from name_prefix \"<name>-vpc-flow-logs-\"."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}

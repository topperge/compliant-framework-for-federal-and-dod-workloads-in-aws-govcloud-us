variable "name" {
  description = "Name prefix for resources (pName). transit-init.yml passes \"inspection\"."
  type        = string
  default     = "inspection"
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
  description = "VPC CIDR (SSM: /compliant/framework/transit/inspection-vpc/cidr). No default in config.json.template."
  type        = string
}

variable "instance_tenancy" {
  description = "VPC instance tenancy (SSM: /compliant/framework/transit/inspection-vpc/instance-tenancy). Not in config.json.template; defaults to \"default\" like firewall-vpc."
  type        = string
  default     = "default"
}

variable "public_subnet_a_cidr" {
  description = "Public subnet A CIDR (SSM: /compliant/framework/transit/inspection-vpc/public-subnet/a/cidr)."
  type        = string
}

variable "public_subnet_b_cidr" {
  description = "Public subnet B CIDR (SSM: /compliant/framework/transit/inspection-vpc/public-subnet/b/cidr)."
  type        = string
}

variable "transit_gateway_attachment_subnet_a_cidr" {
  description = "TGW attachment subnet A CIDR (SSM: /compliant/framework/transit/inspection-vpc/tgw-attach-subnet/a/cidr)."
  type        = string
}

variable "transit_gateway_attachment_subnet_b_cidr" {
  description = "TGW attachment subnet B CIDR (SSM: /compliant/framework/transit/inspection-vpc/tgw-attach-subnet/b/cidr)."
  type        = string
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

variable "firewall_subnet_a_cidr" {
  description = "Firewall subnet A CIDR (SSM: /compliant/framework/transit/inspection-vpc/firewall-subnet/a/cidr)."
  type        = string
}

variable "firewall_subnet_b_cidr" {
  description = "Firewall subnet B CIDR (SSM: /compliant/framework/transit/inspection-vpc/firewall-subnet/b/cidr)."
  type        = string
}

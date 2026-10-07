variable "name" {
  description = "Name prefix for resource Name tags (pName)."
  type        = string
  default     = "management-services"
}

variable "vpc_cidr" {
  description = "VPC CIDR (SSM /compliant/framework/management-services/management-services-vpc/cidr)."
  type        = string
  default     = "10.0.20.0/22"
}

variable "instance_tenancy" {
  description = "VPC instance tenancy (SSM /compliant/framework/management-services/management-services-vpc/instance-tenancy)."
  type        = string
  default     = "default"
}

variable "application_subnet_a_cidr" {
  description = "Application subnet A CIDR (SSM /compliant/framework/management-services/management-services-vpc/application-subnet/a/cidr)."
  type        = string
  default     = "10.0.20.0/24"
}

variable "application_subnet_b_cidr" {
  description = "Application subnet B CIDR (SSM /compliant/framework/management-services/management-services-vpc/application-subnet/b/cidr)."
  type        = string
  default     = "10.0.21.0/24"
}

variable "data_subnet_a_cidr" {
  description = "Data subnet A CIDR (SSM /compliant/framework/management-services/management-services-vpc/data-subnet/a/cidr)."
  type        = string
  default     = "10.0.23.0/26"
}

variable "data_subnet_b_cidr" {
  description = "Data subnet B CIDR (SSM /compliant/framework/management-services/management-services-vpc/data-subnet/b/cidr)."
  type        = string
  default     = "10.0.23.64/26"
}

variable "transit_gateway_attachment_subnet_a_cidr" {
  description = "Transit gateway attachment subnet A CIDR (SSM /compliant/framework/management-services/management-services-vpc/tgw-attach-subnet/a/cidr)."
  type        = string
  default     = "10.0.23.208/28"
}

variable "transit_gateway_attachment_subnet_b_cidr" {
  description = "Transit gateway attachment subnet B CIDR (SSM /compliant/framework/management-services/management-services-vpc/tgw-attach-subnet/b/cidr)."
  type        = string
  default     = "10.0.23.224/28"
}

variable "transit_gateway_id" {
  description = "ID of the transit gateway (owned by the transit account, shared to this account via RAM) to attach the VPC to."
  type        = string
}

variable "logging_bucket_arn" {
  description = "ARN of the S3 bucket receiving VPC flow logs. Defaults to arn:<partition>:s3:::flow-logs-<account>-<region> (created by the management-services-logging module), as in management-services-init.yml."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}

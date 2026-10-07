variable "tags" {
  description = "Tags applied to all taggable resources (IAM roles; IAM groups are not taggable)."
  type        = map(string)
  default     = {}
}

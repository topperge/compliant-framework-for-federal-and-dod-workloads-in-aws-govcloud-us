output "bucket_name" {
  description = "Name of the Terraform state bucket; use it in backend.hcl."
  value       = aws_s3_bucket.state.id
}

output "kms_key_arn" {
  description = "KMS key encrypting the state bucket; use it as kms_key_id in backend.hcl."
  value       = aws_kms_key.state.arn
}

output "backend_hcl" {
  description = "Suggested contents of terraform/backend.hcl."
  value       = <<-EOT
    bucket       = "${aws_s3_bucket.state.id}"
    region       = "${data.aws_region.current.region}"
    encrypt      = true
    kms_key_id   = "${aws_kms_key.state.arn}"
    use_lockfile = true
  EOT
}

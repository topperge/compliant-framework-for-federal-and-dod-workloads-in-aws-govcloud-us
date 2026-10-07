# Source: source/repositories/compliant-framework-central-core/templates/security/security-guard-duty.yml
#
# Deploy once per account per region.

#
# Amazon GuardDuty
#
resource "aws_guardduty_detector" "guard_duty" {
  enable                       = true
  finding_publishing_frequency = var.finding_publishing_frequency
  tags                         = var.tags
}

# S3 protection (replaces the deprecated detector `datasources.s3_logs` block)
resource "aws_guardduty_detector_feature" "s3_data_events" {
  detector_id = aws_guardduty_detector.guard_duty.id
  name        = "S3_DATA_EVENTS"
  status      = var.enable_s3_protection ? "ENABLED" : "DISABLED"
}

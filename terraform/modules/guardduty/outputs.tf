# The CFN template has no outputs; exposed for composition.

output "detector_id" {
  description = "ID of the GuardDuty detector."
  value       = aws_guardduty_detector.guard_duty.id
}

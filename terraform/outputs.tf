output "n8n_url" {
  description = "n8n UI and webhook host"
  value       = "https://${local.n8n_fqdn}"
}

output "n8n_webhook_endpoint" {
  description = "Webhook the action group posts to"
  value       = "https://${local.n8n_fqdn}/webhook/incident"
}

output "n8n_basic_auth_user" {
  description = "n8n UI username"
  value       = var.n8n_basic_auth_user
}

output "n8n_basic_auth_password" {
  description = "n8n UI password (terraform output -raw n8n_basic_auth_password)"
  value       = random_password.basic_auth.result
  sensitive   = true
}

output "target_vm_id" {
  description = "Resource ID of the demo target VM the runbook restarts"
  value       = azurerm_linux_virtual_machine.target.id
}

output "target_vm_name" {
  description = "Name of the demo target VM"
  value       = azurerm_linux_virtual_machine.target.name
}

output "alert_name" {
  description = "Metric alert the workflow verifies during the resolve loop"
  value       = azurerm_monitor_metric_alert.cpu.name
}

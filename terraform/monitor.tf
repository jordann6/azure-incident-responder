# ---------------------------------------------------------------------------
# The incident path: a metric alert on the target VM that posts the Common
# Alert Schema to the n8n webhook through an action group. Azure delivers the
# webhook directly, so there is no SNS-style subscription confirmation.
# ---------------------------------------------------------------------------

resource "azurerm_monitor_action_group" "incident" {
  name                = "ag-${var.project}"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "incident"

  webhook_receiver {
    name                    = "n8n"
    service_uri             = "https://${local.n8n_fqdn}/webhook/incident"
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "cpu" {
  name                = "alert-${var.project}-cpu-high"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_linux_virtual_machine.target.id]
  description         = "Target VM CPU at or above ${var.cpu_alarm_threshold}% over 5 minutes"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThanOrEqual"
    threshold        = var.cpu_alarm_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.incident.id
  }
}

# ---------------------------------------------------------------------------
# n8n control plane on Azure Container Apps. The environment hands out a
# publicly trusted HTTPS FQDN (*.azurecontainerapps.io), so unlike the AWS
# build there is no ALB, ACM cert, or custom domain to manage.
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}"
  location = var.location
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.project}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.project}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
}

# n8n secrets are generated here rather than hardcoded or passed as tfvars.
# random_password values live only in state (held in the private azurerm
# backend); nothing sensitive is committed.
resource "random_password" "basic_auth" {
  length  = 24
  special = false
}

resource "random_password" "encryption_key" {
  length  = 48
  special = false
}

locals {
  n8n_app_name = "ca-${var.project}-n8n"
  n8n_fqdn     = "${local.n8n_app_name}.${azurerm_container_app_environment.main.default_domain}"
}

resource "azurerm_container_app" "n8n" {
  name                         = local.n8n_app_name
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  revision_mode                = "Single"

  ingress {
    external_enabled = true
    target_port      = 5678
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  secret {
    name  = "basic-auth-password"
    value = random_password.basic_auth.result
  }

  secret {
    name  = "encryption-key"
    value = random_password.encryption_key.result
  }

  template {
    min_replicas = 1
    max_replicas = 1

    container {
      name   = "n8n"
      image  = var.n8n_image
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "N8N_HOST"
        value = local.n8n_fqdn
      }
      env {
        name  = "N8N_PORT"
        value = "5678"
      }
      env {
        name  = "N8N_PROTOCOL"
        value = "https"
      }
      env {
        name  = "WEBHOOK_URL"
        value = "https://${local.n8n_fqdn}/"
      }
      env {
        name  = "N8N_BASIC_AUTH_ACTIVE"
        value = "true"
      }
      env {
        name  = "N8N_BASIC_AUTH_USER"
        value = var.n8n_basic_auth_user
      }
      env {
        name  = "GENERIC_TIMEZONE"
        value = "America/New_York"
      }
      env {
        name  = "N8N_DIAGNOSTICS_ENABLED"
        value = "false"
      }
      env {
        name        = "N8N_BASIC_AUTH_PASSWORD"
        secret_name = "basic-auth-password"
      }
      env {
        name        = "N8N_ENCRYPTION_KEY"
        secret_name = "encryption-key"
      }
    }
  }
}

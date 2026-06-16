variable "location" {
  type        = string
  description = "Azure region for all resources. eastus2 is the default because eastus periodically runs out of Container Apps (AKS-backed) capacity."
  default     = "eastus2"
}

variable "project" {
  type        = string
  description = "Name prefix applied to all resources"
  default     = "incident-responder"
}

variable "vnet_cidr" {
  type        = string
  description = "Address space for the project VNet"
  default     = "10.40.0.0/16"
}

variable "n8n_image" {
  type        = string
  description = "Container image for the n8n service"
  default     = "n8nio/n8n:latest"
}

variable "n8n_basic_auth_user" {
  type        = string
  description = "Basic auth username for the n8n UI"
  default     = "admin"
}

variable "target_vm_size" {
  type        = string
  description = "Size of the demo target VM"
  default     = "Standard_B1s"
}

variable "admin_username" {
  type        = string
  description = "Admin username on the demo target VM"
  default     = "azureuser"
}

variable "cpu_alarm_threshold" {
  type        = number
  description = "Percentage CPU that trips the incident alert"
  default     = 80
}

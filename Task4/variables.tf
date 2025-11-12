variable "yc_service_account_key_file" {
  description = "IAM token"
  type        = string
  sensitive   = true
}

variable "vm_service_account_id" {
  description = "service account ID for VM"
  type        = string
}

variable "yc_cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
  sensitive   = true
}

variable "yc_folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
  sensitive   = true
}

variable "yc_zone" {
  description = "Yandex Cloud zone"
  type        = string
  default     = "ru-central1-a"
}

variable "project_prefix" {
  description = "Prefix for project resources (used in bucket names)"
  type        = string
  default     = "future-2.0"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
}
variable cloud_id {
  description = "Cloud"
}
variable folder_id {
  description = "Folder"
}
variable zone {
  description = "Zone"
  # Значение по умолчанию
  default = "ru-central1-a"
}
variable public_key_path {
  # Описание переменной
  description = "Path to the public key used for ssh access"
  default = "~/.ssh/id_rsa.pub"
}
#variable image_id {
#  description = "Disk image"
#}
variable subnet_id {
  description = "Subnet"
}
variable service_account_key_file {
  description = "key.json"
}
variable private_key_path {
  description = "Private key path for ssh"
  default = "~/.ssh/id_rsa"
}
variable count_app {
  description = "app counter"
  type        = number
  default     = 1
}

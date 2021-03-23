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
variable count_host {
  description = "host counter"
  type        = number
  default     = 2
}
variable count_master {
  description = "master counter"
  type        = number
  default     = 1
}
variable count_worker {
  description = "worker counter"
  type        = number
  default     = 1
}

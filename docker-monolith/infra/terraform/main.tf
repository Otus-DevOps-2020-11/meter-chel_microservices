provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
  version = "~> 0.35.0"
}

resource "yandex_compute_instance" "docker" {
   name                      = "docker-app-${count.index}"
   platform_id               = "standard-v2"
   count                     = var.count_app

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
    # Указать id образа с Docker
      image_id = var.image_id
    }

  }
  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }

  zone                     = var.zone
  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

  connection {
    type  = "ssh"
    host  = self.network_interface.0.nat_ip_address
    user  = "ubuntu"
    agent = false
    private_key = file(var.private_key_path)
  }

   provisioner "local-exec" {
     command = "sleep 60"
   }

   provisioner "local-exec" {
     command = "ansible-playbook --inventory ${self.network_interface.0.nat_ip_address}, run_app.yml"
     working_dir = "../ansible"
   }

}

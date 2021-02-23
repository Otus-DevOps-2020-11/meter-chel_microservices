provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
#  version = "~> 0.35.0"
}

data "yandex_compute_image" "my_image" {
  family = "ubuntu-1804-lts"
}


resource "yandex_compute_instance" "gitlab" {
   name                      = "gitlab-ci-${count.index}"
   platform_id               = "standard-v2"
   count                     = var.count_app

  resources {
    cores  = 2
    memory = 4
    core_fraction = 50
  }

  boot_disk {
    initialize_params {
    # Указать id образа с Docker
    #  image_id = var.image_id
      image_id = data.yandex_compute_image.my_image.id
      size = 50
    }

  }
  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }

  zone = var.zone
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
}


resource "local_file" "generate_inventory" {
  content = templatefile("inventory.tmpl", {
    name = yandex_compute_instance.gitlab.*.name,
    extip = yandex_compute_instance.gitlab.*.network_interface.0.nat_ip_address,
    }
  )
  filename = "../ansible/inventory.ini"

   provisioner "local-exec" {
     command = "sleep 60"
   }

   provisioner "local-exec" {
#     command = "ansible-playbook --inventory ${self.network_interface.0.nat_ip_address}, install_docker.yml"
#     command = "ansible-playbook --inventory yandex_compute_instance.gitlab.*.network_interface.0.nat_ip_address, site.yml"
     command = "ansible-playbook site.yml"
     working_dir = "../ansible"
   }

#   provisioner "local-exec" {
#     command = "ansible-playbook docker-compose.yml"
#     working_dir = "../ansible"
#   }

}

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


resource "yandex_compute_instance" "node" {
   name                      = "node-${count.index}"
   platform_id               = "standard-v2"
   count                     = var.count_app

  resources {
    cores  = 4
    memory = 4
    core_fraction = 100
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.my_image.id
      size = 40
#      disk-type = "network-ssd"
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
    name = yandex_compute_instance.node.*.name,
    extip = yandex_compute_instance.node.*.network_interface.0.nat_ip_address,
    }
  )
  filename = "../ansible/inventory.ini"

   provisioner "local-exec" {
     command = "sleep 40"
   }

   provisioner "local-exec" {
     command = "ansible-playbook install_docker.yml"
#     command = "ansible-playbook run_node.yml"
     working_dir = "../ansible"
   }

}

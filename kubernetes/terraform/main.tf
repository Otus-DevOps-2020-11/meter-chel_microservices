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


resource "yandex_vpc_network" "kubernetes-network" {
   name = "kubernetes-network"
}

 resource "yandex_vpc_subnet" "kubernetes-subnet" {
   name           = "kubernetes-subnet"
   zone           = "ru-central1-a"
   network_id     = yandex_vpc_network.kubernetes-network.id
   v4_cidr_blocks = ["10.244.0.0/16"]
 }


resource "yandex_compute_instance" "node" {
   name                      = "node-${count.index}"
   platform_id               = "standard-v2"
   count                     = var.count_host

  resources {
    cores  = 4
    memory = 8
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
    subnet_id = yandex_vpc_subnet.kubernetes-subnet.id
#    subnet_id = var.subnet_id
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
    master_count = var.count_master,
    worker_count = var.count_worker
    }
  )
  filename = "../ansible/inventory.ini"

   provisioner "local-exec" {
     command = "sleep 40"
   }

   provisioner "local-exec" {
     command = "ansible-playbook node-all.yml"
     working_dir = "../ansible"
   }

   provisioner "local-exec" {
     command = "ansible-playbook master.yml"
     working_dir = "../ansible"
   }

   provisioner "local-exec" {
     command = "ansible-playbook worker.yml"
     working_dir = "../ansible"
   }

}

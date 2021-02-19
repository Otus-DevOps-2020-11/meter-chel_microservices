output "external_ip_address_app" {
  value = yandex_compute_instance.gitlab.*.network_interface.0.nat_ip_address
}

resource "local_file" "AnsibleInventory" {
  content = templatefile("inventory.tmpl",
    {
    name = yandex_compute_instance.gitlab.*.name
    extip = yandex_compute_instance.gitlab.*.network_interface.0.nat_ip_address
    }
  )
  filename = "../ansible/inventory.ini"
}

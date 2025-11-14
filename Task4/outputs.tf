output "network_info" {
  description = "Network configuration information"
  value = {
    vpc_id     = yandex_vpc_network.data_platform_network.id
    subnet_id  = yandex_vpc_subnet.data_platform_subnet.id
    cidr_block = yandex_vpc_subnet.data_platform_subnet.v4_cidr_blocks[0]
  }
}

output "vm_instances" {
  description = "Virtual machines information"
  value = {
    med_data_vm = {
      name        = yandex_compute_instance.med_data_vm.name
      internal_ip = yandex_compute_instance.med_data_vm.network_interface.0.ip_address
      external_ip = yandex_compute_instance.med_data_vm.network_interface.0.nat_ip_address
    }
    fintech_data_vm = {
      name        = yandex_compute_instance.fintech_data_vm.name
      internal_ip = yandex_compute_instance.fintech_data_vm.network_interface.0.ip_address
      external_ip = yandex_compute_instance.fintech_data_vm.network_interface.0.nat_ip_address
    }
    datahub = {
      name        = yandex_compute_instance.datahub.name
      internal_ip = yandex_compute_instance.datahub.network_interface.0.ip_address
      external_ip = yandex_compute_instance.datahub.network_interface.0.nat_ip_address
    }
  }
}

output "database_info" {
  description = "Database connection information"
  value = {
    datahub_db = {
      host = yandex_mdb_postgresql_cluster.datahub_db.host[0].fqdn
      port = 5432
    }
  }
  sensitive = true
}

output "storage_info" {
  description = "Storage resources information"
  value = {
    backup_bucket = yandex_storage_bucket.backup.bucket
    data_disks = {
      med_data_disk     = yandex_compute_disk.med_data_disk.id
      fintech_data_disk = yandex_compute_disk.fintech_data_disk.id
    }
  }
}

output "service_urls" {
  description = "URLs for accessing services"
  value = {
    datahub_ui = "http://${yandex_compute_instance.datahub.network_interface.0.nat_ip_address}:9002"
  }
}
terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.99.0"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  service_account_key_file = var.yc_service_account_key_file
  cloud_id                 = var.yc_cloud_id
  folder_id                = var.yc_folder_id
  zone                     = var.yc_zone
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

resource "yandex_vpc_network" "data_platform_network" {
  name = "data-platform-network"
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "nat_route_table" {
  name       = "nat-route-table"
  network_id = yandex_vpc_network.data_platform_network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

resource "yandex_vpc_subnet" "data_platform_subnet" {
  name           = "data-platform-subnet"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.data_platform_network.id
  v4_cidr_blocks = ["10.10.0.0/24"]
  route_table_id = yandex_vpc_route_table.nat_route_table.id
}

resource "yandex_vpc_security_group" "data_platform_sg" {
  name       = "data-platform-sg"
  network_id = yandex_vpc_network.data_platform_network.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]  # SSH
  }

  ingress {
    protocol       = "TCP"
    port           = 9002
    v4_cidr_blocks = ["0.0.0.0/0"]  # DataHub UI
  }

  ingress {
    protocol       = "TCP"
    from_port      = 8000
    to_port        = 9000
    v4_cidr_blocks = [yandex_vpc_subnet.data_platform_subnet.v4_cidr_blocks[0]]  # внутренний трафик
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]  # весь исходящий трафик
  }
}

resource "yandex_compute_disk" "med_data_disk" {
  name = "med-data-disk"
  type = "network-ssd"
  zone = var.yc_zone
  size = 50
}

resource "yandex_compute_disk" "fintech_data_disk" {
  name = "fintech-data-disk"
  type = "network-ssd"
  zone = var.yc_zone
  size = 50
}

resource "yandex_compute_instance" "med_data_vm" {
  name               = "med-data-vm"
  platform_id        = "standard-v3"
  zone               = var.yc_zone
  service_account_id = var.vm_service_account_id

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
      type     = "network-ssd"
    }
  }

  secondary_disk {
    disk_id = yandex_compute_disk.med_data_disk.id
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.data_platform_subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.data_platform_sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}

resource "yandex_compute_instance" "fintech_data_vm" {
  name               = "fintech-data-vm"
  platform_id        = "standard-v3"
  zone               = var.yc_zone
  service_account_id = var.vm_service_account_id

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
      type     = "network-ssd"
    }
  }

  secondary_disk {
    disk_id = yandex_compute_disk.fintech_data_disk.id
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.data_platform_subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.data_platform_sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}

resource "yandex_compute_instance" "datahub" {
  name               = "datahub"
  platform_id        = "standard-v3"
  zone               = var.yc_zone
  service_account_id = var.vm_service_account_id

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.data_platform_subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.data_platform_sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}

resource "yandex_mdb_postgresql_cluster" "datahub_db" {
  name        = "datahub-db"
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.data_platform_network.id

  config {
    version = 15
    resources {
      resource_preset_id = "s2.micro"
      disk_type_id       = "network-ssd"
      disk_size          = 10
    }
  }

  host {
    zone      = var.yc_zone
    subnet_id = yandex_vpc_subnet.data_platform_subnet.id
  }
}

resource "yandex_storage_bucket" "backup" {
  bucket = "backup-${var.project_prefix}"
  max_size = 1024

  versioning {
    enabled = true
  }
}
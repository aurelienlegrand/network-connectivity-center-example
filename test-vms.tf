resource "google_compute_instance" "instance1" {
  project      = var.project_id
  name         = "hub-instance1"
  machine_type = "n2-standard-2"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      labels = {
        my_label = "value"
      }
    }
  }

  network_interface {
    subnetwork         = "vpc0-europe-west1"
    subnetwork_project = var.project_id
  }
}

resource "google_compute_instance" "instance2" {
  project      = var.project_id
  name         = "on-premise-instance1"
  machine_type = "n2-standard-2"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      labels = {
        my_label = "value"
      }
    }
  }

  network_interface {
    subnetwork         = "vpc4-europe-west1"
    subnetwork_project = var.project_id
  }
}

resource "google_compute_instance" "instance3" {
  project      = var.project_id
  name         = "spoke1-instance1"
  machine_type = "n2-standard-2"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      labels = {
        my_label = "value"
      }
    }
  }

  network_interface {
    subnetwork         = "vpc1-europe-west1"
    subnetwork_project = var.project_id
  }
}

resource "google_compute_instance" "instance4" {
  project      = var.project_id
  name         = "spoke2-instance1"
  machine_type = "n2-standard-2"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      labels = {
        my_label = "value"
      }
    }
  }

  network_interface {
    subnetwork         = "vpc2-europe-west1"
    subnetwork_project = var.project_id
  }
}

resource "google_compute_instance" "instance5" {
  project      = var.project_id
  name         = "spoke1-overlapping-instance1"
  machine_type = "n2-standard-2"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      labels = {
        my_label = "value"
      }
    }
  }

  network_interface {
    subnetwork         = "vpc1-overlapping-subnet"
    subnetwork_project = var.project_id
  }
}
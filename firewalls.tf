resource "google_compute_firewall" "fw-vcp1" {
  name    = "test-firewall1"
  project = var.project_id
  network = module.vpc1.self_link

  allow {
    protocol = "icmp"
  }
    allow {
    protocol = "tcp"
  }
  source_ranges = ["10.0.0.0/8", "192.168.0.0/16"]
}

resource "google_compute_firewall" "fw-vcp2" {
  name    = "test-firewall2"
  project = var.project_id
  network = module.vpc2.self_link

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
  }
  source_ranges = ["10.0.0.0/8", "192.168.0.0/16"]
}

resource "google_compute_firewall" "fw-vcp3" {
  name    = "test-firewall3"
  project = var.project_id
  network = module.vpc3.self_link

  allow {
    protocol = "icmp"
  }
    allow {
    protocol = "tcp"
  }
  source_ranges = ["10.0.0.0/8", "192.168.0.0/16"]
}

resource "google_compute_firewall" "fw-vcp4" {
  name    = "test-firewall4"
  project = var.project_id
  network = module.vpc4.self_link

  allow {
    protocol = "icmp"
  }
    allow {
    protocol = "tcp"
  }
  source_ranges = ["10.0.0.0/8", "192.168.0.0/16"]
}
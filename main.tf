// VPC connected to "on-premise"
module "vpc1" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc"
  project_id = var.project_id
  name       = "ncc-hybrid"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "vpc0-europe-west1"
      region        = "europe-west1"
    },
    {
      ip_cidr_range = "10.0.16.0/24"
      name          = "vpc0-europe-west2"
      region        = "europe-west2"
    }
  ]
}

// NCC Spoke VPC 1
module "vpc2" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc"
  project_id = var.project_id
  name       = "ncc-spoke1"
  subnets = [
    {
      ip_cidr_range = "10.1.0.0/24"
      name          = "vpc1-europe-west1"
      region        = "europe-west1"
    },
    {
      ip_cidr_range = "10.1.16.0/24"
      name          = "vpc1-europe-west2"
      region        = "europe-west2"
    },
    {
      ip_cidr_range = "10.10.0.0/24"
      name          = "vpc1-overlapping-subnet"
      region        = "europe-west1"
    }
  ]
  subnets_private_nat = [
    {
      ip_cidr_range = "192.168.1.0/24"
      name          = "spoke1-nat"
      region        = "europe-west1"
    }
  ]
}

// NCC Spoke VPC 2
module "vpc3" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc"
  project_id = var.project_id
  name       = "ncc-spoke2"
  subnets = [
    {
      ip_cidr_range = "10.2.0.0/24"
      name          = "vpc2-europe-west1"
      region        = "europe-west1"
    },
    {
      ip_cidr_range = "10.2.16.0/24"
      name          = "vpc2-europe-west2"
      region        = "europe-west2"
    }
  ]
}

// VPC to simulate on-premise, connected to ncc-hybrid VPC by HA VPNs
module "vpc4" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc"
  project_id = var.project_id
  name       = "on-premise"
  subnets = [
    {
      ip_cidr_range = "10.4.0.0/24"
      name          = "vpc4-europe-west1"
      region        = "europe-west1"
    },
    {
      ip_cidr_range = "10.4.16.0/24"
      name          = "vpc4-europe-west2"
      region        = "europe-west2"
    },
    {
      ip_cidr_range = "10.10.0.0/24"
      name          = "vpc4-overlapping-subnet"
      region        = "europe-west1"
    }
  ]
}

// NCC Configuration

resource "google_network_connectivity_hub" "ncc-hub" {
  name        = "ncc-hub"
  description = "NCC hub"
  project     = var.project_id
}

resource "google_network_connectivity_spoke" "ncc-spoke-vpc0" {
  name        = "hybrid-vpc"
  location    = "global"
  description = "A sample spoke VPC"
  project     = var.project_id

  hub = google_network_connectivity_hub.ncc-hub.id
  linked_vpc_network {
    exclude_export_ranges = [
      "172.16.0.0/20",
      "192.168.0.0/24"]
    uri = module.vpc1.self_link
  }
}

resource "google_network_connectivity_spoke" "ncc-spoke-vpc1" {
  name        = "spoke-vpc-1"
  location    = "global"
  description = "A sample spoke VPC"
  project     = var.project_id

  hub = google_network_connectivity_hub.ncc-hub.id
  linked_vpc_network {
    exclude_export_ranges = [
      "172.16.0.0/20",
      "192.168.0.0/24"]
    uri = module.vpc2.self_link
  }
}

resource "google_network_connectivity_spoke" "ncc-spoke-vpc2" {
  name        = "spoke-vpc-2"
  location    = "global"
  description = "A sample spoke VPC"
  project     = var.project_id

  hub = google_network_connectivity_hub.ncc-hub.id
  linked_vpc_network {
    exclude_export_ranges = [
      "172.16.0.0/20",
      "192.168.0.0/24"
    ]
    uri = module.vpc3.self_link
  }
}

resource "google_network_connectivity_spoke" "tunnel1" {
  name        = "vpn-tunnel-1-spoke"
  location    = "europe-west1"
  description = "VPN 1 to on-premise"
  project     = var.project_id

  hub = google_network_connectivity_hub.ncc-hub.id
  linked_vpn_tunnels {
    uris                       = [module.vpn-1.tunnel_self_links["remote-0"]]
    site_to_site_data_transfer = false
    include_import_ranges      = ["ALL_IPV4_RANGES"]
  }
}

resource "google_network_connectivity_spoke" "tunnel2" {
  name        = "vpn-tunnel-2-spoke"
  location    = "europe-west1"
  description = "VPN 2 to on-premise"
  project     = var.project_id

  hub = google_network_connectivity_hub.ncc-hub.id
  linked_vpn_tunnels {
    uris                       = [module.vpn-1.tunnel_self_links["remote-1"]]
    site_to_site_data_transfer = false
    include_import_ranges      = ["ALL_IPV4_RANGES"]
  }
}

module "nat0" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-cloudnat"
  project_id     = var.project_id
  region         = "europe-west1"
  name           = "nat0"
  router_network = module.vpc1.self_link
}

module "spoke1-nat" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-cloudnat"
  project_id     = var.project_id
  region         = "europe-west1"
  name           = "spoke1-hybridnat"
  type           = "PRIVATE"
  router_network = module.vpc2.self_link
  config_source_subnetworks = {
    all = false
    subnetworks = [
      {
        self_link = module.vpc2.subnet_ids["europe-west1/vpc1-overlapping-subnet"]
      }
    ]
  }
  config_port_allocation = {
    enable_endpoint_independent_mapping = false
    enable_dynamic_port_allocation      = true
  }
  rules = [
    {
      description = "private nat"
      # NAT for both hybrid + NCC Hub
      // match       = "nexthop.is_hybrid || nexthop.hub == '//networkconnectivity.googleapis.com/projects/ale-test-network-268016/locations/global/hubs/ncc-hub'"
      # NAT for NCC Hub only
      match       = "nexthop.hub == '//networkconnectivity.googleapis.com/projects/ale-test-network-268016/locations/global/hubs/ncc-hub'"
      source_ranges = [
        module.vpc2.subnets_private_nat["europe-west1/spoke1-nat"].id
      ]
    }
  ]
  logging_filter = "ALL"
}

module "nat1" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-cloudnat"
  project_id     = var.project_id
  region         = "europe-west1"
  name           = "nat1"
  router_network = module.vpc2.self_link

}
module "nat4" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-cloudnat"
  project_id     = var.project_id
  region         = "europe-west1"
  name           = "nat4"
  router_network = module.vpc4.self_link
}
module "nat3" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-cloudnat"
  project_id     = var.project_id
  region         = "europe-west1"
  name           = "nat3"
  router_network = module.vpc3.self_link
}
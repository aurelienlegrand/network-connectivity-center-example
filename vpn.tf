module "vpn-1" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpn-ha"
  project_id = var.project_id
  region     = "europe-west1"
  network    = module.vpc1.self_link
  name       = "hub-to-on-prem"
  peer_gateways = {
    default = { gcp = module.vpn-2.self_link }
  }
  router_config = {
    asn = 64514
    custom_advertise = {
      all_subnets = false
      ip_ranges = {
        "10.0.0.0/24" = "hub-eu-west1",
        "10.0.16.0/24" = "hub-eu-west4",
        "10.1.0.0/24" = "spoke1-eu-west1",
        "10.1.16.0/24" = "spoke1-eu-west4",
        "10.2.0.0/24" = "spoke2-eu-west1",
        "10.2.16.0/24" = "spoke2-eu-west4",
        "192.168.1.0/24" = "spoke1-nat"
      }
    }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 64513
      }
      bgp_session_range     = "169.254.1.2/30"
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64513
      }
      bgp_session_range     = "169.254.2.2/30"
      vpn_gateway_interface = 1
    }
  }
}

module "vpn-2" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpn-ha"
  project_id    = var.project_id
  region        = "europe-west1"
  network       = module.vpc4.self_link
  name          = "on-prem-to-hub"
  router_config = { asn = 64513 
  custom_advertise = {
      all_subnets = false
      ip_ranges = {
        "10.4.0.0/24" = "eu-west1",
        "10.4.16.0/24" = "eu-west4"
      }
    }
  }
  peer_gateways = {
    default = { gcp = module.vpn-1.self_link }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.2"
        asn     = 64514
      }
      bgp_session_range     = "169.254.1.1/30"
      shared_secret         = module.vpn-1.shared_secrets["remote-0"]
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.2"
        asn     = 64514
      }
      bgp_session_range     = "169.254.2.1/30"
      shared_secret         = module.vpn-1.shared_secrets["remote-1"]
      vpn_gateway_interface = 1
    }
  }
}
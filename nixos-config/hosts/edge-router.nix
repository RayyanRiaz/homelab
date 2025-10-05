{
  config,
  lib,
  pkgs,
  ...
}:

let
  wanInterface = "enp2s0";
  lanInterface = "enp3s0";
  homeVlan = {
    name = "home";
    id = "10";
  };
  serverVlan = {
    name = "servers";
    id = "20";
  };
  cameraVlan = {
    name = "cameras";
    id = "30";
  };
in
{
  imports = [
    ../modules/common.nix
    ../modules/ssh.nix
    ../users/rayyan
  ];

  networking.hostName = "edge-router";
  system.stateVersion = "25.05";
  nixpkgs.config.allowUnfree = false;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    btop
    mtr
    nmap
    tcpdump
    ethtool
    nftables
    wireguard-tools
    traceroute
    bmon
    lldpd
    iproute2
    wireguard-tools
  ];

  powerManagement.cpuFreqGovernor = "performance";
  services.thermald.enable = true;

  networking = {
    enableIPv6 = true;

    useDHCP = lib.mkForce false;
    # https://www.reddit.com/r/archlinux/comments/ge61lr/dhcpcd_vs_netword_preference_and_experience/
    useNetworkd = true; # enable systemd-networkd (recommended for advanced network setups)
    dhcpcd.enable = false; # disable dhcpcd if using systemd-networkd

    # nameservers = [
    #   "1.1.1.1"
    #   "8.8.8.8"
    # ];

    vlans = {
      home = {
        id = 10;
        interface = lanInterface;
      };
      servers = {
        id = 20;
        interface = lanInterface;
      };
      cameras = {
        id = 30;
        interface = lanInterface;
      };
    };

    interfaces = {
      "${wanInterface}".useDHCP = true; # get IP from ISP
      "${lanInterface}".useDHCP = false; # static IPs on VLANs below

      "${homeVlan.name}".ipv4.addresses = [
        {
          address = "192.168.${homeVlan.id}.1";
          prefixLength = 24;
        }
      ];
      "${serverVlan.name}".ipv4.addresses = [
        {
          address = "192.168.${serverVlan.id}.1";
          prefixLength = 24;
        }
      ];
      "${cameraVlan.name}".ipv4.addresses = [
        {
          address = "192.168.${cameraVlan.id}.1";
          prefixLength = 24;
        }
      ];
    };

    nat = {
      enable = true;
      externalInterface = wanInterface;
      internalInterfaces = [
        homeVlan.name
        serverVlan.name
        cameraVlan.name
      ];
      # enableIPv6 = false; # change if you want IPv6 NAT / routing
    };

    firewall = {
      enable = false;
    };
  };

  boot.kernel.sysctl = {
    # --- Kernel: enable forwarding ---
    # allow the box to forward packets between interfaces
    # also see https://francis.begyn.be/blog/nixos-home-router
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;

    # # performance / backlog tuning
    # "net.core.netdev_max_backlog" = 4096;
    # "net.ipv4.tcp_max_syn_backlog" = 8192;
    # "net.ipv4.tcp_fin_timeout" = 15;
    # "net.ipv4.tcp_tw_reuse" = 1;
    # "net.netfilter.nf_conntrack_max" = 524288;
    # "net.netfilter.nf_conntrack_tcp_timeout_established" = 1800;
    # "net.core.rmem_max" = 16777216;
    # "net.core.wmem_max" = 16777216;
    # "net.ipv4.conf.all.rp_filter" = 0;
    # "net.ipv4.conf.default.rp_filter" = 0;
  };

  # # tune NIC buffers & offloads
  # systemd.services."nic-tune" = {
  #   description = "NIC tuning for router performance";
  #   wantedBy = [ "multi-user.target" ];
  #   script = ''
  #     for iface in ${wanInterface.name} ${lanInterface.name}; do
  #       ethtool -K $iface gro off gso off tso off rx on tx on
  #       ethtool -G $iface rx 4096 tx 4096
  #     done
  #   '';
  #   serviceConfig.Type = "oneshot";
  # };

  services = {
    # chrony = {
    #   enable = true;
    #   enableNTS = true;
    #   servers = [ "pool.ntp.org" ];
    # };

    dnsmasq = {
      enable = true;
      # ask dnsmasq to bind to the VLAN interfaces and hand out ranges
      settings = {
        # domain-needed = true;
        # bogus-priv = true;
        # bind-interfaces = true;
        interface = [
          homeVlan.name
          serverVlan.name
          cameraVlan.name
        ];
        server = [
          "1.1.1.1"
          "1.0.0.1"
          "8.8.8.8"
        ];
        dhcp-range = [
          "set:${homeVlan.name},192.168.${homeVlan.id}.100,192.168.${homeVlan.id}.200,12h"
          "set:${serverVlan.name},192.168.${serverVlan.id}.50,192.168.${serverVlan.id}.150,24h"
          "set:${cameraVlan.name},192.168.${cameraVlan.id}.50,192.168.${cameraVlan.id}.150,24h"
        ];
        dhcp-option = [
          "tag:${homeVlan.name},option:router,192.168.${homeVlan.id}.1"
          "tag:${homeVlan.name},option:dns-server,192.168.${homeVlan.id}.1"
          "tag:${homeVlan.name},option:ntp-server,192.168.${homeVlan.id}.1"
          "tag:${serverVlan.name},option:router,192.168.${serverVlan.id}.1"
          "tag:${serverVlan.name},option:dns-server,192.168.${serverVlan.id}.1"
          "tag:${serverVlan.name},option:ntp-server,192.168.${serverVlan.id}.1"
          "tag:${cameraVlan.name},option:router,192.168.${cameraVlan.id}.1"
          "tag:${cameraVlan.name},option:dns-server,192.168.${cameraVlan.id}.1"
          "tag:${cameraVlan.name},option:ntp-server,192.168.${cameraVlan.id}.1"
        ];
        bind-interfaces = true;
        dhcp-authoritative = true;
        log-dhcp = true;
      };
    };

  };

  virtualisation.docker.enable = lib.mkForce false;
}

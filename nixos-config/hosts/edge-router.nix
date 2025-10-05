{
  config,
  lib,
  pkgs,
  ...
}:

let
  wanInterface = "enp1s0";
  lanInterface = "enp2s0";
  homeVlan = "${lanInterface}.10";
  serverVlan = "${lanInterface}.20";
  cameraVlan = "${lanInterface}.30";
in
{
  imports = [
    ../modules/common.nix
    ../modules/ssh.nix
    # ../modules/system_cleanup.nix
    ../modules/monitoring.nix

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
    mtr
    nmap
    tcpdump
    ethtool
    nftables
    wireguard-tools
    traceroute
    bmon
    lldpd
  ];

  programs.zsh.enable = true;

  powerManagement.cpuFreqGovernor = "performance";
  services.thermald.enable = true;

  networking = {
    useDHCP = false;
    useNetworkd = true;
    dhcpcd.enable = false;
    enableIPv6 = true;

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
      "${wanInterface}".useDHCP = true;
      "${lanInterface}".useDHCP = false;

      "${homeVlan}".ipv4.addresses = [
        {
          address = "192.168.10.1";
          prefixLength = 24;
        }
      ];
      "${serverVlan}".ipv4.addresses = [
        {
          address = "192.168.20.1";
          prefixLength = 24;
        }
      ];
      "${cameraVlan}".ipv4.addresses = [
        {
          address = "192.168.30.1";
          prefixLength = 24;
        }
      ];
    };

    nat = {
      enable = true;
      externalInterface = wanInterface;
      internalInterfaces = [
        homeVlan
        serverVlan
        cameraVlan
      ];
      enableIPv6 = false;
    };

    firewall = {
      enable = true;
      allowPing = true;
      logRefusedConnections = true;
      trustedInterfaces = [
        homeVlan
        serverVlan
      ];

      extraInputRules = ''
        # Allow management from trusted VLANs
        iifname { "${homeVlan}", "${serverVlan}" } tcp dport { 22, 80, 443, 9100, 19999 } accept
        iifname { "${homeVlan}", "${serverVlan}" } udp dport { 53, 67, 123 } accept

        # Cameras: DNS/DHCP/NTP only
        iifname "${cameraVlan}" udp dport { 53, 67, 123 } accept
        iifname "${cameraVlan}" tcp dport 53 accept

        # Drop management attempts from WAN
        iifname "${wanInterface}" tcp dport { 22, 9100, 19999 } drop
        iifname "${wanInterface}" udp dport { 53, 67, 123 } drop
      '';

      extraForwardRules = ''
        # Cameras cannot reach internet
        iifname "${cameraVlan}" oifname "${wanInterface}" reject with icmpx type admin-prohibited;

        # Cameras can talk to internal networks
        iifname "${cameraVlan}" oifname "${homeVlan}" accept
        iifname "${cameraVlan}" oifname "${serverVlan}" accept
      '';
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;

    # performance / backlog tuning
    "net.core.netdev_max_backlog" = 4096;
    "net.ipv4.tcp_max_syn_backlog" = 8192;
    "net.ipv4.tcp_fin_timeout" = 15;
    "net.ipv4.tcp_tw_reuse" = 1;
    "net.netfilter.nf_conntrack_max" = 524288;
    "net.netfilter.nf_conntrack_tcp_timeout_established" = 1800;
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
  };

  # tune NIC buffers & offloads
  systemd.services."nic-tune" = {
    description = "NIC tuning for router performance";
    wantedBy = [ "multi-user.target" ];
    script = ''
      for iface in ${wanInterface} ${lanInterface}; do
        ethtool -K $iface gro off gso off tso off rx on tx on
        ethtool -G $iface rx 4096 tx 4096
      done
    '';
    serviceConfig.Type = "oneshot";
  };

  services = {
    chrony = {
      enable = true;
      enableNTS = true;
      servers = [ "pool.ntp.org" ];
    };

    dnsmasq = {
      enable = true;
      settings = {
        domain-needed = true;
        bogus-priv = true;
        bind-interfaces = true;
        interface = [
          homeVlan
          serverVlan
          cameraVlan
        ];
        listen-address = [
          "192.168.10.1"
          "192.168.20.1"
          "192.168.30.1"
        ];
        server = [
          "1.1.1.1"
          "1.0.0.1"
          "8.8.8.8"
        ];
        dhcp-range = [
          "set:home,192.168.10.100,192.168.10.200,12h"
          "set:servers,192.168.20.50,192.168.20.150,24h"
          "set:cameras,192.168.30.50,192.168.30.150,24h"
        ];
        dhcp-option = [
          "tag:home,option:router,192.168.10.1"
          "tag:home,option:dns-server,192.168.10.1"
          "tag:home,option:ntp-server,192.168.10.1"
          "tag:servers,option:router,192.168.20.1"
          "tag:servers,option:dns-server,192.168.20.1"
          "tag:servers,option:ntp-server,192.168.20.1"
          "tag:cameras,option:router,192.168.30.1"
          "tag:cameras,option:dns-server,192.168.30.1"
          "tag:cameras,option:ntp-server,192.168.30.1"
        ];
      };
    };

    suricata = {
      enable = true;
      interfaces = [
        wanInterface
        homeVlan
        serverVlan
      ];
      settings = {
        af-packet = [
          {
            interface = wanInterface;
            threads = 2;
            cluster-type = "cluster_flow";
          }
          {
            interface = homeVlan;
            threads = 1;
            cluster-type = "cluster_flow";
          }
          {
            interface = serverVlan;
            threads = 1;
            cluster-type = "cluster_flow";
          }
        ];
        detect-thread-ratio = 1.2;
        vars = {
          HOME_NET = "[192.168.10.0/24,192.168.20.0/24,192.168.30.0/24]";
          EXTERNAL_NET = "!$HOME_NET";
        };
        default-log-dir = "/var/log/suricata";
      };
    };

    netdata = {
      enable = true;
      config.global = {
        "memory mode" = "dbengine";
        "default port" = 19999;
      };
    };

    lldpd.enable = true;
    prometheus.exporters.node.extraFlags = [ "--collector.conntrack" ];
    prometheus.exporters.node.openFirewall = true;
    fail2ban.enable = true;
  };

  virtualisation.docker.enable = lib.mkForce false;

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
}

{ config, lib, pkgs, ... }:

let
  wanInterface = "enp1s0";
  lanInterface = "enp2s0";
  homeVlan = "${lanInterface}.10";
  serverVlan = "${lanInterface}.20";
  cameraVlan = "${lanInterface}.30";
in {
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

      "${lanInterface}" = {
        useDHCP = false;
      };

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
      internalInterfaces = [ homeVlan serverVlan cameraVlan ];
      enableIPv6 = false;
    };

    firewall = {
      enable = true;
      allowPing = true;
      logRefusedConnections = true;
      trustedInterfaces = [ homeVlan serverVlan ];

      interfaces."${wanInterface}" = {
        allowedTCPPorts = [ ];
        allowedUDPPorts = [ ];
      };

      extraInputRules = ''
        # Allow management from trusted VLANs
        iifname { "${homeVlan}", "${serverVlan}" } tcp dport { 22, 80, 443, 9100, 19999 } accept
        iifname { "${homeVlan}", "${serverVlan}" } udp dport { 53, 67, 123 } accept

        # Cameras only get DNS, DHCP and NTP from the router
        iifname "${cameraVlan}" udp dport { 53, 67, 123 } accept
        iifname "${cameraVlan}" tcp dport 53 accept

        # Drop unexpected management traffic from WAN
        iifname "${wanInterface}" tcp dport { 22, 9100, 19999 } drop
        iifname "${wanInterface}" udp dport { 53, 67, 123 } drop
      '';

      extraForwardRules = ''
        # Prevent camera network from reaching the internet
        iifname "${cameraVlan}" oifname "${wanInterface}" drop

        # Cameras can talk to internal networks
        iifname "${cameraVlan}" oifname "${homeVlan}" accept
        iifname "${cameraVlan}" oifname "${serverVlan}" accept
      '';
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.netfilter.nf_conntrack_max" = 262144;
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
        interface = [ homeVlan serverVlan cameraVlan ];
        listen-address = [ "192.168.10.1" "192.168.20.1" "192.168.30.1" ];
        server = [ "1.1.1.1" "1.0.0.1" "8.8.8.8" ];
        dhcp-range = [
          "set:home,192.168.10.100,192.168.10.200,12h"
          "set:servers,192.168.20.50,192.168.20.150,24h"
          "set:cameras,192.168.30.50,192.168.30.150,24h"
        ];
        dhcp-option = [
          "tag:home,option:router,192.168.10.1"
          "tag:home,option:dns-server,192.168.10.1"
          "tag:servers,option:router,192.168.20.1"
          "tag:servers,option:dns-server,192.168.20.1"
          "tag:cameras,option:router,192.168.30.1"
          "tag:cameras,option:dns-server,192.168.30.1"
        ];
      };
    };

    suricata = {
      enable = true;
      interfaces = [ wanInterface lanInterface homeVlan serverVlan cameraVlan ];
      settings = {
        vars = {
          "HOME_NET" = "[192.168.10.0/24,192.168.20.0/24,192.168.30.0/24]";
          "EXTERNAL_NET" = "!$HOME_NET";
        };
        default-log-dir = "/var/log/suricata";
      };
    };

    cadvisor = {
      enable = lib.mkForce false;
    };

    netdata = {
      enable = true;
      config = {
        global = {
          "memory mode" = "dbengine";
          "default port" = 19999;
        };
      };
    };

    lldpd = {
      enable = true;
    };

    prometheus = {
      exporters = {
        node = {
          extraFlags = [ "--collector.conntrack" ];
        };
      };
    };

    fail2ban = {
      enable = true;
    };
  };

  services.prometheus.exporters.node.openFirewall = true;

  virtualisation.docker.enable = lib.mkForce false;

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
}
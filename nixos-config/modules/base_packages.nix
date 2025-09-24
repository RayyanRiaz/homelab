{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    zsh
    vim
    git
    curl
    wget
    tree
    btop
    age
    tmux
    zip
    unzip
    gnupg
    openssl
    rsync
    pciutils     # lspci
    usbutils     # lsusb
    nettools     # netstat, ifconfig, etc.
    iperf3       # network testing
    jq           # JSON CLI
    fd           # better find
    ripgrep      # better grep


    # Network debug
    traceroute
    dnsutils # dig, nslookup
    iproute2 # ip command
    tcpdump
    ethtool

    # --- Monitoring & Debug ---
    glances
    sysstat
    iotop
    iftop
    nload

    # --- Containers & VM ---
    docker
    docker-compose
    kubectl
  ];

  # Enable Docker service
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    liveRestore = false;
  };

}
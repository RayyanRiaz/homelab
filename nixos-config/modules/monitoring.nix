{ config, pkgs, ... }:

{
  # Node-level system metrics (CPU, RAM, disk, network)
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    openFirewall = true;
  };

  # Container metrics (Docker, containerd, Podman)
  services.cadvisor = {
    enable = true;
    port = 8080;
    openFirewall = true;
  };
}

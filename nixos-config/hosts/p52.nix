{ config, pkgs, ... }:

{
  imports = [
    ../modules/common.nix
    ../modules/ssh.nix
    ../modules/base_packages.nix

    ../users/rayyan
  ];

  networking.hostName = "p52";
  system.stateVersion = "25.05";
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.logind = {
    lidSwitch = "ignore";
    lidSwitchDocked = "ignore";
    lidSwitchExternalPower = "ignore";
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = false;   # false => proprietary; true => open-source
    modesetting.enable = true;
    powerManagement.enable = false;
    prime = {
      # Bus IDs from `lspci | grep -E "VGA|3D"`
      offload.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    # https://nixos.wiki/wiki/Nvidia#Determining_the_Correct_Driver_Version
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

}

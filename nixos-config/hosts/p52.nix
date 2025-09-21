{ config, pkgs, ... }:

{
  imports = [
    ../modules/common.nix
    ../modules/users.nix
    ../modules/ssh.nix
  ];

  networking.hostName = "p52";
  system.stateVersion = "24.05";
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;


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

  # Install CUDA toolkit + driver
  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit
    nvidia_x11
  ];

}

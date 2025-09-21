{ config, pkgs, ... }:

{
  imports = [
    ../modules/common.nix
    ../modules/users.nix
    ../modules/ssh.nix
  ];

  networking.hostName = "p52";
  system.stateVersion = "24.05";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # machine-specific packages
  environment.systemPackages = with pkgs; [
    vim
    git
  ];
}

{ pkgs, ... }:

{
  home-manager.users.rayyan = import ./home.nix;

  programs.zsh.enable = true;
  users.users.rayyan = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    password = "changeme";
    shell = pkgs.zsh;
  };
}
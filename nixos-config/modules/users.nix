{ pkgs, ... }:

{
  users.users.rayyan = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    password = "changeme";
  };
}

{ pkgs, ... }:

{
  users.users.rayyan = {
    isNormalUser = true;
    extraGroups = [ "wheel", "docker" ];
    password = "changeme";
  };
}

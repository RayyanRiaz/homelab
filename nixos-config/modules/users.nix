{ pkgs, ... }:

{
  users.users.rayyan = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # sudo
    password = "changeme";     # change after first login
  };
}

{ ... }:

{
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true; # later switch to keys
}

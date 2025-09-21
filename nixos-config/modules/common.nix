{ config, pkgs, ... }:


{
  time.timeZone = "Asia/Karachi";
  i18n.defaultLocale = "en_US.UTF-8";

  networking.useDHCP = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}

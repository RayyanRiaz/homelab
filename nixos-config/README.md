# My NixOS Config

This repo contains declarative configs for my machines.

## Install (on P52)

```bash
git clone https://github.com/RayyanRiaz/homelab
cd my-nixos-config/nixos-config

# Partition & format according to disko config
sudo env NIX_CONFIG="experimental-features = nix-command flakes" nix run github:nix-community/disko -- --mode disko ./disko/p52.nix

# Install NixOS using flake config
sudo env NIX_CONFIG="experimental-features = nix-command flakes" nixos-install --flake .#p52

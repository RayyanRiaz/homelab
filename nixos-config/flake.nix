{
  description = "NixOS configurations for Rayyan's machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    disko.url = "github:nix-community/disko";
  };

  outputs = { self, nixpkgs, disko, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
    in {
      nixosConfigurations = {
        p52 = lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/p52.nix
            disko.nixosModules.disko
            ./disko/p52.nix
          ];
        };

        # future machine example:
        # serverX = lib.nixosSystem {
        #   inherit system;
        #   modules = [
        #     ./hosts/serverX.nix
        #     disko.nixosModules.disko
        #     ./disko/serverX.nix
        #   ];
        # };
      };
    };
}

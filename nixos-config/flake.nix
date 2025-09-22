{
  description = "NixOS configurations for Rayyan's machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    disko.url = "github:nix-community/disko";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, home-manager, ... }:
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
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            }
          ];
        };

        # future machine example:
        # serverX = lib.nixosSystem {
        #   inherit system;
        #   modules = [
        #     ./hosts/serverX.nix
        #     disko.nixosModules.disko
        #     ./disko/serverX.nix
        #     home-manager.nixosModules.home-manager
        #     {
        #       home-manager.useGlobalPkgs = true;
        #       home-manager.useUserPackages = true;
        #     }
        #   ];
        # };
      };
    };
}

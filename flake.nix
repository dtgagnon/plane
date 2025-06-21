{
  description = "Nix flake for packaging Plane";
  # See nix/docs/NIX-USAGE.md for detailed usage instructions

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = import ./nix/overlays;
        };
        plane = import ./nix/packages { inherit pkgs system; };
      in {
        packages = {
          default = plane;
          plane = plane;
        };
      }) // {
        overlays = import ./nix/overlays;
        # NixOS module
        nixosModules = let 
          # Function to create a module that uses the flake's own plane package
          planeModule = { lib, pkgs, ... }: { 
            imports = [ (import ./nix/modules { inherit lib pkgs; planePackage = self.packages.${pkgs.system}.plane; }) ]; 
          };
        in {
          # Pass the plane package to the module so it can be used directly
          default = planeModule;
          plane = planeModule;
        };
      };
}

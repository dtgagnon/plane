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
        pkgs = import nixpkgs { inherit system; };
        plane = import ./nix/package.nix { inherit pkgs system; };
      in
      {
        packages = {
          default = plane;
          plane = plane;
        };
        nixosModules = {
          default = import ./nix/nixos-module.nix;
          plane = import ./nix/nixos-module.nix;
        };
      }
    );
}

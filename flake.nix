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
      in {
        packages = {
          default = plane;
          plane = plane;
        };
        
        # Development shell with Plane package available
        devShells.default = pkgs.mkShell {
          buildInputs = [ plane ];
          shellHook = ''
            echo "Plane development environment"
            echo "Available commands:"
            echo "  plane help    - Show Plane CLI help"
            echo "  plane setup   - Setup Plane configuration"
            echo ""
          '';
        };
      }) // {
        # NixOS module
        nixosModules = {
          default = import ./nix/nixos-module.nix;
          plane = import ./nix/nixos-module.nix;
        };
        
        # Example configurations
        examples = {
          basic = import ./nix/example-configuration.nix;
        };
      };
}

{ planePackage ? null, ... }:

# Import all submodules to build a complete configuration
{
  imports = [
    # Pass the package to options.nix
    (import ./options.nix { inherit planePackage; })
    ./system.nix
    ./services.nix
    ./networking.nix
    ./dependencies.nix
    ./environment.nix
  ];
}

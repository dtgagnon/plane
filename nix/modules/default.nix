{ ... }:

# Import all submodules to build a complete configuration
{
  imports = [
    ./options.nix
    ./system.nix
    ./services.nix
    ./networking.nix
    ./dependencies.nix
    ./environment.nix
  ];
}

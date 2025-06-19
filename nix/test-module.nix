#!/usr/bin/env nix-instantiate
# Simple test to validate NixOS module syntax

{ pkgs ? import <nixpkgs> {} }:

let
  # Import the module
  planeModule = import ./nixos-module.nix;
  
  # Create a minimal test configuration
  testConfig = {
    config = {
      services.plane = {
        enable = true;
        domain = "test.example.com";
        secretKeyFile = "/dev/null";
        database = {
          local = true;
          passwordFile = "/dev/null";
        };
        rabbitmq = {
          local = true;
          passwordFile = "/dev/null";
        };
        storage = {
          local = true;
          credentialsFile = "/dev/null";
        };
      };
    };
    
    lib = pkgs.lib;
    pkgs = pkgs // {
      plane = pkgs.hello; # Dummy package for testing
    };
  };
  
  # Evaluate the module
  evaluation = pkgs.lib.evalModules {
    modules = [ planeModule testConfig ];
  };

in {
  # Return success if module evaluates without errors
  success = evaluation.config.services.plane.enable;
  
  # Show some configuration values for verification
  domain = evaluation.config.services.plane.domain;
  webPort = evaluation.config.services.plane.web.port;
  apiPort = evaluation.config.services.plane.api.port;
  
  # Check that systemd services are generated
  hasApiService = builtins.hasAttr "plane-api" evaluation.config.systemd.services;
  hasWebService = builtins.hasAttr "plane-web" evaluation.config.systemd.services;
  hasMigrateService = builtins.hasAttr "plane-migrate" evaluation.config.systemd.services;
  
  # Check nginx configuration
  hasNginxConfig = builtins.hasAttr evaluation.config.services.plane.domain evaluation.config.services.nginx.virtualHosts;
}
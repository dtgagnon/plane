# Example NixOS configuration for Plane
{ config, pkgs, ... }:

{
  # Import the Plane module
  imports = [
    ../modules
  ];

  # Basic Plane configuration with all local services
  services.plane = {
    enable = true;
    domain = "plane.example.com";
    
    # Enable all frontend services
    web.enable = true;
    admin.enable = true;
    space.enable = true;
    live.enable = false; # Optional real-time collaboration
    
    # Backend services
    api = {
      enable = true;
      workers = 2;
      port = 3103;
    };
    worker.enable = true;
    beat.enable = true;
    
    # Use local services for all dependencies
    database.local = true;
    cache.local = true;
    rabbitmq.local = true;
    storage.local = true;
    
    # Enable nginx reverse proxy and ACME
    nginx.enable = true;
    acme.enable = true;
    
    # Secret files (these need to be created manually)
    secretKeyFile = "/var/lib/secrets/plane-secret-key";
    database.passwordFile = "/var/lib/secrets/plane-db-password";
    rabbitmq.passwordFile = "/var/lib/secrets/plane-rabbitmq-password";
    storage.credentialsFile = "/var/lib/secrets/plane-storage-credentials";
  };

  # Additional system configuration
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # Optional: Configure PostgreSQL settings
  services.postgresql = {
    settings = {
      max_connections = 200;
      shared_buffers = "256MB";
      effective_cache_size = "1GB";
    };
  };

  # Example secret file creation (for development only)
  # In production, use proper secret management
  systemd.tmpfiles.rules = [
    "d /var/lib/secrets 0700 root root -"
    "f /var/lib/secrets/plane-secret-key 0600 root root - django-insecure-change-this-in-production"
    "f /var/lib/secrets/plane-db-password 0600 root root - plane_db_password"
    "f /var/lib/secrets/plane-rabbitmq-password 0600 root root - plane_mq_password"
    "f /var/lib/secrets/plane-storage-credentials 0600 root root - plane_access_key\nplane_secret_key"
  ];
}

# Advanced configuration examples:

/*
# External database configuration
services.plane = {
  enable = true;
  domain = "plane.example.com";
  
  database = {
    local = false;
    host = "db.example.com";
    port = 5432;
    name = "plane_prod";
    user = "plane_user";
    passwordFile = "/run/secrets/db-password";
  };
  
  cache = {
    local = false;
    host = "redis.example.com";
    port = 6379;
  };
  
  storage = {
    local = false;
    protocol = "https";
    host = "s3.amazonaws.com";
    region = "us-west-2";
    bucket = "my-plane-uploads";
    credentialsFile = "/run/secrets/aws-credentials";
  };
};
*/

/*
# Custom port configuration
services.plane = {
  enable = true;
  domain = "plane.example.com";
  
  web.port = 4000;
  admin.port = 4001;
  api.port = 4002;
  space.port = 4003;
  live = {
    enable = true;
    port = 4004;
  };
};
*/

/*
# Development configuration with custom package
services.plane = {
  enable = true;
  domain = "plane.local";
  package = pkgs.callPackage ./package.nix {};
  
  # Disable HTTPS for local development
  acme.enable = false;
  nginx.enable = true; # Still use nginx but without SSL
};
*/
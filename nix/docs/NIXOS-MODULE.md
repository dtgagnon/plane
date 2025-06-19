# Plane NixOS Module

This document describes how to use the Plane NixOS module to deploy Plane on NixOS systems.

## Overview

The Plane NixOS module provides a declarative way to deploy and configure Plane project management platform on NixOS. It includes:

- **Backend services**: Django API, Celery worker, Celery beat scheduler
- **Frontend services**: Web interface, admin interface, public space, live collaboration
- **Dependencies**: PostgreSQL, Redis, RabbitMQ, MinIO (all optional and configurable)
- **Reverse proxy**: nginx with automatic HTTPS via ACME
- **Security**: systemd hardening, credential management, file permissions

## Quick Start

### 1. Add to your flake.nix

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    plane.url = "github:makeplane/plane/add/nix";  # or local path
  };

  outputs = { self, nixpkgs, plane }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        plane.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
```

### 2. Basic configuration.nix

```nix
{ config, pkgs, ... }:

{
  services.plane = {
    enable = true;
    domain = "plane.example.com";
    
    # Use local services (recommended for single-server deployment)
    database.local = true;
    cache.local = true;
    rabbitmq.local = true;
    storage.local = true;
    
    # Enable HTTPS with automatic certificates
    acme.enable = true;
    
    # Secret files (create these manually)
    secretKeyFile = "/var/lib/secrets/plane-secret-key";
    database.passwordFile = "/var/lib/secrets/plane-db-password";
    rabbitmq.passwordFile = "/var/lib/secrets/plane-rabbitmq-password";
    storage.credentialsFile = "/var/lib/secrets/plane-storage-credentials";
  };

  # Open firewall for HTTP/HTTPS
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

### 3. Create secret files

```bash
sudo mkdir -p /var/lib/secrets
sudo chmod 700 /var/lib/secrets

# Generate Django secret key
echo "$(openssl rand -base64 32)" | sudo tee /var/lib/secrets/plane-secret-key
sudo chmod 600 /var/lib/secrets/plane-secret-key

# Database password
echo "secure_db_password" | sudo tee /var/lib/secrets/plane-db-password
sudo chmod 600 /var/lib/secrets/plane-db-password

# RabbitMQ password
echo "secure_mq_password" | sudo tee /var/lib/secrets/plane-rabbitmq-password
sudo chmod 600 /var/lib/secrets/plane-rabbitmq-password

# MinIO credentials (access_key on first line, secret_key on second)
cat << EOF | sudo tee /var/lib/secrets/plane-storage-credentials
minio_access_key
minio_secret_key
EOF
sudo chmod 600 /var/lib/secrets/plane-storage-credentials
```

### 4. Deploy

```bash
sudo nixos-rebuild switch
```

## Configuration Options

### Basic Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `services.plane.enable` | bool | false | Enable Plane service |
| `services.plane.domain` | string | required | Domain name for Plane |
| `services.plane.package` | package | pkgs.plane | Plane package to use |
| `services.plane.user` | string | "plane" | System user for Plane services |
| `services.plane.group` | string | "plane" | System group for Plane services |
| `services.plane.stateDir` | string | "/var/lib/plane" | State directory |
| `services.plane.secretKeyFile` | string | required | Django secret key file |

### Service-Specific Options

#### API Backend
```nix
services.plane.api = {
  enable = true;        # Enable API service
  port = 3103;          # API port
  workers = 1;          # Number of Gunicorn workers
};
```

#### Frontend Services
```nix
services.plane.web = {
  enable = true;        # Main web interface
  port = 3101;          # Web service port
};

services.plane.admin = {
  enable = true;        # Admin interface
  port = 3102;          # Admin service port
};

services.plane.space = {
  enable = true;        # Public space interface
  port = 3104;          # Space service port
};

services.plane.live = {
  enable = false;       # Live collaboration (optional)
  port = 3105;          # Live service port
};
```

#### Worker Services
```nix
services.plane.worker.enable = true;  # Celery worker
services.plane.beat.enable = true;    # Celery beat scheduler
```

### Database Configuration

#### Local PostgreSQL
```nix
services.plane.database = {
  local = true;                                      # Use local PostgreSQL
  name = "plane";                                    # Database name
  user = "plane";                                    # Database user
  passwordFile = "/var/lib/secrets/db-password";     # Password file
};
```

#### External Database
```nix
services.plane.database = {
  local = false;                                     # Use external DB
  host = "db.example.com";                          # Database host
  port = 5432;                                      # Database port
  name = "plane_prod";                              # Database name
  user = "plane_user";                              # Database user
  passwordFile = "/run/secrets/db-password";        # Password file
};
```

### Cache Configuration (Redis)

#### Local Redis
```nix
services.plane.cache = {
  local = true;         # Use local Redis
  host = "127.0.0.1";   # Redis host
  port = 6379;          # Redis port
};
```

#### External Redis
```nix
services.plane.cache = {
  local = false;
  host = "redis.example.com";
  port = 6379;
};
```

### Message Queue (RabbitMQ)

#### Local RabbitMQ
```nix
services.plane.rabbitmq = {
  local = true;                                         # Use local RabbitMQ
  host = "127.0.0.1";                                   # RabbitMQ host
  port = 5672;                                          # RabbitMQ port
  user = "plane";                                       # RabbitMQ user
  vhost = "plane";                                      # RabbitMQ virtual host
  passwordFile = "/var/lib/secrets/rabbitmq-password";  # Password file
};
```

### Storage Configuration

#### Local MinIO
```nix
services.plane.storage = {
  local = true;                                      # Use local MinIO
  host = "127.0.0.1";                               # MinIO host
  port = 9000;                                      # MinIO port
  bucket = "uploads";                               # Bucket name
  protocol = "http";                                # Protocol (http/https)
  region = "us-east-1";                             # AWS region
  credentialsFile = "/var/lib/secrets/minio-creds"; # Credentials file
};
```

#### External S3
```nix
services.plane.storage = {
  local = false;
  protocol = "https";
  host = "s3.amazonaws.com";
  region = "us-west-2";
  bucket = "my-plane-uploads";
  credentialsFile = "/run/secrets/aws-credentials";
};
```

### Reverse Proxy and SSL

```nix
services.plane.nginx.enable = true;   # Enable nginx reverse proxy
services.plane.acme.enable = true;    # Enable automatic HTTPS certificates
```

## Advanced Configuration Examples

### Multi-Server Deployment

```nix
# Web/API server
services.plane = {
  enable = true;
  domain = "plane.example.com";
  
  # Frontend services
  web.enable = true;
  admin.enable = true;
  space.enable = true;
  
  # API service
  api = {
    enable = true;
    workers = 4;
  };
  
  # External dependencies
  database = {
    local = false;
    host = "db.internal.example.com";
    name = "plane";
    user = "plane";
    passwordFile = "/run/secrets/db-password";
  };
  
  cache = {
    local = false;
    host = "redis.internal.example.com";
  };
  
  rabbitmq = {
    local = false;
    host = "mq.internal.example.com";
    user = "plane";
    passwordFile = "/run/secrets/mq-password";
  };
  
  storage = {
    local = false;
    protocol = "https";
    host = "s3.amazonaws.com";
    region = "us-west-2";
    bucket = "plane-prod-uploads";
    credentialsFile = "/run/secrets/aws-credentials";
  };
};
```

```nix
# Worker server (separate machine)
services.plane = {
  enable = true;
  domain = "plane.example.com";
  
  # Only enable worker services
  api.enable = false;
  web.enable = false;
  admin.enable = false;
  space.enable = false;
  nginx.enable = false;
  
  worker.enable = true;
  beat.enable = true;
  
  # Same external dependencies as web server
  # ... (database, cache, rabbitmq, storage config)
};
```

### Development Configuration

```nix
services.plane = {
  enable = true;
  domain = "plane.local";
  
  # Custom package (e.g., from local build)
  package = pkgs.callPackage ./custom-plane.nix {};
  
  # All local services for development
  database.local = true;
  cache.local = true;
  rabbitmq.local = true;
  storage.local = true;
  
  # No HTTPS for local development
  acme.enable = false;
  nginx.enable = true;
  
  # Development ports
  web.port = 3000;
  admin.port = 3001;
  api.port = 8000;
  space.port = 3002;
};

# Add to /etc/hosts for local development
networking.hosts = {
  "127.0.0.1" = [ "plane.local" ];
};
```

## Security Considerations

### Secret Management

The module uses systemd's `LoadCredential` feature for secure secret handling:

- Secrets are loaded from files specified in configuration
- Each service gets its own copy in `/run/credentials/<service-name>/`
- Files are only readable by the service user
- Secrets are automatically cleaned up when services stop

### systemd Security Hardening

All services include security hardening:

- `PrivateTmp=true` - Private /tmp directory
- `ProtectSystem=strict` - Read-only root filesystem
- `ProtectHome=true` - No access to user home directories
- `NoNewPrivileges=true` - Cannot gain new privileges
- `ReadWritePaths` - Only specific directories are writable

### File Permissions

- Configuration files: 0640 (readable by service user only)
- Secret files: 0600 (readable by root only)
- State directories: 0750 (writable by service user only)

## Troubleshooting

### Check Service Status

```bash
# Check all Plane services
systemctl status plane-*

# Check specific services
systemctl status plane-api
systemctl status plane-worker
systemctl status plane-migrate
```

### View Logs

```bash
# View API logs
journalctl -u plane-api -f

# View worker logs
journalctl -u plane-worker -f

# View all Plane logs
journalctl -u 'plane-*' -f
```

### Check Configuration

```bash
# Verify environment file
sudo cat /etc/plane/plane.env

# Check secret files
sudo ls -la /var/lib/secrets/

# Test database connection
sudo -u plane psql -h localhost -U plane -d plane -c "SELECT version();"
```

### Common Issues

1. **Services fail to start**: Check that all secret files exist and have correct permissions
2. **Database connection errors**: Verify PostgreSQL is running and credentials are correct
3. **Permission denied**: Check that `/var/lib/plane` exists and has correct ownership
4. **ACME certificate errors**: Ensure domain points to your server and ports 80/443 are open

## Migration from Docker

To migrate from a Docker deployment:

1. **Backup data**: Export database and file uploads
2. **Configure NixOS module** with same domain and database settings
3. **Import data**: Restore database and upload files to new locations
4. **Update DNS**: Point domain to NixOS server
5. **Test thoroughly**: Verify all functionality works

## Performance Tuning

### Database

```nix
services.postgresql = {
  settings = {
    max_connections = 200;
    shared_buffers = "256MB";
    effective_cache_size = "1GB";
    random_page_cost = 1.1;
    checkpoint_completion_target = 0.9;
    wal_buffers = "16MB";
    default_statistics_target = 100;
  };
};
```

### API Workers

```nix
services.plane.api.workers = 4;  # Adjust based on CPU cores
```

### Redis Memory

```nix
services.redis.servers.plane = {
  settings = {
    maxmemory = "512mb";
    maxmemory-policy = "allkeys-lru";
  };
};
```

## Contributing

To contribute to the NixOS module:

1. Fork the repository
2. Make changes to `nix/nixos-module.nix`
3. Test with example configuration
4. Submit pull request

## Support

For issues with the NixOS module:

- File issues on GitHub: https://github.com/makeplane/plane/issues
- Join community discussions: https://discord.gg/A92xrEGCge
- Check documentation: https://docs.plane.so
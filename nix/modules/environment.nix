{ lib, config, pkgs, ... }:

let
  inherit (lib) mkIf;
  cfg = config.services.plane;
  
  # Generate environment configuration
  planeEnvFile = ''
    # Django settings
    DEBUG=0
    DJANGO_SETTINGS_MODULE=plane.settings.production
    
    # Database configuration (password loaded via LoadCredential when available)
    POSTGRES_DB=${cfg.database.name}
    POSTGRES_USER=${cfg.database.user}
    POSTGRES_HOST=${cfg.database.host}
    POSTGRES_PORT=${toString cfg.database.port}
    
    # Redis configuration
    REDIS_URL=redis://${cfg.cache.host}:${toString cfg.cache.port}/0
    
    # RabbitMQ configuration (password loaded via LoadCredential when available)
    RABBITMQ_USER=${cfg.rabbitmq.user}
    RABBITMQ_HOST=${cfg.rabbitmq.host}
    RABBITMQ_PORT=${toString cfg.rabbitmq.port}
    RABBITMQ_VHOST=${cfg.rabbitmq.vhost}
    
    # Storage configuration (credentials loaded via LoadCredential when available)
    USE_MINIO=1
    AWS_REGION=${cfg.storage.region}
    AWS_S3_ENDPOINT_URL=${cfg.storage.protocol}://${cfg.storage.host}:${toString cfg.storage.port}
    AWS_STORAGE_BUCKET_NAME=${cfg.storage.bucket}
    
    # Application settings
    WEB_URL=${cfg.storage.protocol}://${cfg.domain}
    CORS_ALLOWED_ORIGINS=${cfg.storage.protocol}://${cfg.domain}
    
    # Logging configuration
    PLANE_LOG_DIR=${cfg.logDir}
    
    # Email settings (defaults - users should override)
    EMAIL_HOST=localhost
    EMAIL_PORT=587
    EMAIL_USE_TLS=1
    
    # Sentry (optional)
    SENTRY_DSN=""
    
    # Scout APM (optional)
    SCOUT_MONITOR=0
    SCOUT_KEY=""
  '';
in
{
  config = mkIf cfg.enable {
    # Create environment files
    environment.etc = {
      "plane/plane.env" = {
        source = planeEnvFile;
        mode = "0644";
      };
    };
    # Create directory structure  
    systemd.tmpfiles.rules = [
      "d /etc/plane 0755 root root - -"
      "d ${cfg.logDir} 0750 ${cfg.user} ${cfg.group} - -"
      "d ${cfg.stateDir} 0750 ${cfg.user} ${cfg.group} - -"
    ];
  };
}
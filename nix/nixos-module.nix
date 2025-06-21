{ lib
, pkgs
, config
, ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf mkMerge types literalExpression;
  cfg = config.services.plane;
in
{
  options.services.plane = {
    enable = mkEnableOption "Plane project management platform";

    package = mkOption {
      type = types.package;
      default = pkgs.plane or (throw "plane package not found in pkgs");
      defaultText = literalExpression "pkgs.plane";
      description = "The Plane package to use.";
    };

    domain = mkOption {
      type = types.str;
      description = "The domain to use for hosting Plane.";
      example = "plane.example.com";
    };

    user = mkOption {
      type = types.str;
      default = "plane";
      description = "The user to use for the Plane service.";
    };

    group = mkOption {
      type = types.str;
      default = "plane";
      description = "The group to use for the Plane service.";
    };

    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/plane";
      description = "The state directory for the Plane service.";
    };

    secretKeyFile = mkOption {
      type = types.str;
      description = "Path to file containing the Django secret key for the Plane service.";
      example = "/run/secrets/plane-secret-key";
    };

    web = {
      enable = mkEnableOption "Plane web interface" // { default = true; };

      port = mkOption {
        type = types.port;
        default = 3101;
        description = "The port to use for the Plane web service.";
      };
    };

    admin = {
      enable = mkEnableOption "Plane admin interface" // { default = true; };

      port = mkOption {
        type = types.port;
        default = 3102;
        description = "The port to use for the Plane admin service.";
      };
    };

    api = {
      enable = mkEnableOption "Plane API backend" // { default = true; };

      workers = mkOption {
        type = types.int;
        default = 1;
        description = "The number of workers to use for the Plane API service.";
      };

      port = mkOption {
        type = types.port;
        default = 3103;
        description = "The port to use for the Plane API service.";
      };
    };

    space = {
      enable = mkEnableOption "Plane public space interface" // { default = true; };

      port = mkOption {
        type = types.port;
        default = 3104;
        description = "The port to use for the Plane space service.";
      };
    };

    live = {
      enable = mkEnableOption "Plane live collaboration service" // { default = false; };

      port = mkOption {
        type = types.port;
        default = 3105;
        description = "The port to use for the Plane live service.";
      };
    };

    worker = {
      enable = mkEnableOption "Plane Celery worker" // { default = true; };
    };

    beat = {
      enable = mkEnableOption "Plane Celery beat scheduler" // { default = true; };
    };

    database = {
      local = mkEnableOption "local Plane PostgreSQL database";

      user = mkOption {
        type = types.str;
        default = "plane";
        description = "The user to use for the Plane database.";
      };

      passwordFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to file containing the password for the Plane database.";
        example = "/run/secrets/plane-db-password";
      };

      name = mkOption {
        type = types.str;
        default = "plane";
        description = "The name of the Plane database.";
      };

      host = mkOption {
        type = types.str;
        default = "localhost";
        description = "The host of the Plane database.";
      };

      port = mkOption {
        type = types.port;
        default = 5432;
        description = "The port of the Plane database.";
      };
    };

    storage = {
      local = mkEnableOption "local MinIO instance for file storage";

      region = mkOption {
        type = types.str;
        default = "us-east-1";
        description = "The region to use for the Plane storage.";
      };

      credentialsFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to file containing MinIO/S3 credentials (access key and secret key).";
        example = "/run/secrets/plane-storage-credentials";
      };

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "The host of the Plane storage service.";
      };

      port = mkOption {
        type = types.port;
        default = 9000;
        description = "The port of the Plane storage service.";
      };

      bucket = mkOption {
        type = types.str;
        default = "uploads";
        description = "The bucket to use for the Plane storage.";
      };

      protocol = mkOption {
        type = types.enum [ "http" "https" ];
        default = "http";
        description = "The protocol to use for the Plane storage.";
      };
    };

    cache = {
      local = mkEnableOption "local Redis instance for caching";

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "The host of the Plane cache service.";
      };

      port = mkOption {
        type = types.port;
        default = 6379;
        description = "The port of the Plane cache service.";
      };
    };

    rabbitmq = {
      local = mkEnableOption "local RabbitMQ instance for message queuing";

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "The host of the RabbitMQ service.";
      };

      port = mkOption {
        type = types.port;
        default = 5672;
        description = "The port of the RabbitMQ service.";
      };

      user = mkOption {
        type = types.str;
        default = "plane";
        description = "The user for RabbitMQ authentication.";
      };

      passwordFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to file containing the RabbitMQ password.";
        example = "/run/secrets/plane-rabbitmq-password";
      };

      vhost = mkOption {
        type = types.str;
        default = "plane";
        description = "The virtual host for RabbitMQ.";
      };
    };

    acme = {
      enable = mkEnableOption "ACME certificates for Plane domain";
    };

    nginx = {
      enable = mkEnableOption "nginx reverse proxy for Plane" // { default = true; };
    };
  };

  config = mkIf cfg.enable {
    # Assertions for required configuration
    assertions = [
      {
        assertion = cfg.domain != "";
        message = "services.plane.domain must be set";
      }
      {
        assertion = cfg.secretKeyFile != "";
        message = "services.plane.secretKeyFile must be set";
      }
      {
        assertion = cfg.database.local -> cfg.database.passwordFile != null;
        message = "services.plane.database.passwordFile must be set when using local database";
      }
      {
        assertion = cfg.rabbitmq.local -> cfg.rabbitmq.passwordFile != null;
        message = "services.plane.rabbitmq.passwordFile must be set when using local RabbitMQ";
      }
      {
        assertion = cfg.storage.local -> cfg.storage.credentialsFile != null;
        message = "services.plane.storage.credentialsFile must be set when using local storage";
      }
    ];

    # User and group management
    # Note: MinIO user/group creation is handled automatically by services.minio module
    users.users = mkIf (cfg.user == "plane") {
      plane = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.stateDir;
        createHome = true;
        description = "Plane service user";
      };
    };

    users.groups = mkIf (cfg.group == "plane") {
      plane = { };
    };

    # Directory structure
    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.stateDir}/media 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.stateDir}/static 0750 ${cfg.user} ${cfg.group} -"
      "d /var/log/plane 0750 ${cfg.user} ${cfg.group} -"
      "d /etc/plane 0755 root root -"
    ] ++ lib.optionals cfg.storage.local [
      # MinIO data directory within plane stateDir - user creation handled by services.minio
      "d ${cfg.stateDir}/minio 0755 minio minio -"
    ];

    # Conditional service dependencies
    # These leverage existing NixOS modules for battle-tested configurations
    services.postgresql = mkIf cfg.database.local {
      enable = true;
      ensureDatabases = [ cfg.database.name ];
      ensureUsers = [
        {
          name = cfg.database.user;
          ensureDBOwnership = true;
        }
      ];
    };

    services.redis.servers = mkIf cfg.cache.local {
      plane = {
        enable = true;
        port = cfg.cache.port;
        bind = cfg.cache.host;
      };
    };

    services.rabbitmq = mkIf cfg.rabbitmq.local {
      enable = true;
      listenAddress = cfg.rabbitmq.host;
      port = cfg.rabbitmq.port;
    };

    # MinIO object storage - leverages existing NixOS module for user creation and service management
    services.minio = mkIf cfg.storage.local {
      enable = true;
      listenAddress = "${cfg.storage.host}:${toString cfg.storage.port}";
      dataDir = [ "${cfg.stateDir}/minio" ]; # Stores data within plane stateDir for organization
      rootCredentialsFile = cfg.storage.credentialsFile;
    };

    # Environment file generation
    environment.etc."plane/plane.env" = {
      mode = "0640";
      user = cfg.user;
      group = cfg.group;
      text = ''
        # Plane Configuration
        APP_DOMAIN=${cfg.domain}
        WEB_URL=https://${cfg.domain}
        DEBUG=0
        CORS_ALLOWED_ORIGINS=https://${cfg.domain}

        # Database Configuration
        PGHOST=${cfg.database.host}
        PGDATABASE=${cfg.database.name}
        POSTGRES_USER=${cfg.database.user}
        POSTGRES_DB=${cfg.database.name}
        POSTGRES_PORT=${toString cfg.database.port}

        # Redis Configuration
        REDIS_HOST=${cfg.cache.host}
        REDIS_PORT=${toString cfg.cache.port}
        REDIS_URL=redis://${cfg.cache.host}:${toString cfg.cache.port}

        # RabbitMQ Configuration
        RABBITMQ_HOST=${cfg.rabbitmq.host}
        RABBITMQ_PORT=${toString cfg.rabbitmq.port}
        RABBITMQ_USER=${cfg.rabbitmq.user}
        RABBITMQ_VHOST=${cfg.rabbitmq.vhost}

        # Storage Configuration
        USE_MINIO=${if cfg.storage.local then "1" else "0"}
        FILE_SIZE_LIMIT=5242880
        AWS_REGION=${cfg.storage.region}
        AWS_S3_ENDPOINT_URL=${cfg.storage.protocol}://${cfg.storage.host}:${toString cfg.storage.port}
        AWS_S3_BUCKET_NAME=${cfg.storage.bucket}

        # For local file storage (when USE_MINIO=0)
        MEDIA_ROOT=${cfg.stateDir}/media
        STATIC_ROOT=${cfg.stateDir}/static

        # API Configuration
        GUNICORN_WORKERS=${toString cfg.api.workers}
        API_KEY_RATE_LIMIT=60/minute

        # Service URLs
        NEXT_PUBLIC_API_BASE_URL=https://${cfg.domain}/api
        NEXT_PUBLIC_WEB_BASE_URL=https://${cfg.domain}
        NEXT_PUBLIC_SPACE_BASE_URL=https://${cfg.domain}/spaces
        NEXT_PUBLIC_ADMIN_BASE_URL=https://${cfg.domain}/god-mode
      '';
    };

    # Backend systemd services
    systemd.services = {
      # Database migration service (oneshot)
      plane-migrate = mkIf cfg.api.enable {
        description = "Plane database migration";
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.bash ];
        after = [ "network.target" ]
          ++ lib.optional cfg.database.local "postgresql.service"
          ++ lib.optional cfg.cache.local "redis-plane.service"
          ++ lib.optional cfg.rabbitmq.local "rabbitmq.service";
        requires = lib.optional cfg.database.local "postgresql.service"
          ++ lib.optional cfg.cache.local "redis-plane.service"
          ++ lib.optional cfg.rabbitmq.local "rabbitmq.service";

        serviceConfig = {
          Type = "oneshot";
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = cfg.stateDir;
          EnvironmentFile = "/etc/plane/plane.env";
          ExecStart = "${cfg.package}/bin/plane-migrate";
          RemainAfterExit = true;

          # Security hardening
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ cfg.stateDir "/var/log/plane" ];
          NoNewPrivileges = true;

          # Load secrets
          LoadCredential = [
            "secret-key:${cfg.secretKeyFile}"
          ] ++ lib.optionals (cfg.database.passwordFile != null) [
            "db-password:${cfg.database.passwordFile}"
          ] ++ lib.optionals (cfg.rabbitmq.passwordFile != null) [
            "rabbitmq-password:${cfg.rabbitmq.passwordFile}"
          ] ++ lib.optionals (cfg.storage.credentialsFile != null) [
            "storage-credentials:${cfg.storage.credentialsFile}"
          ];
        };

        # Set environment variables from credentials
        environment = {
          SECRET_KEY_FILE = "/run/credentials/plane-migrate/secret-key";
        } // lib.optionalAttrs (cfg.database.passwordFile != null) {
          POSTGRES_PASSWORD_FILE = "/run/credentials/plane-migrate/db-password";
        } // lib.optionalAttrs (cfg.rabbitmq.passwordFile != null) {
          RABBITMQ_PASSWORD_FILE = "/run/credentials/plane-migrate/rabbitmq-password";
        } // lib.optionalAttrs (cfg.storage.credentialsFile != null) {
          STORAGE_CREDENTIALS_FILE = "/run/credentials/plane-migrate/storage-credentials";
        };
      };

      # API service
      plane-api = mkIf cfg.api.enable {
        description = "Plane API server";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" "plane-migrate.service" ]
          ++ lib.optional cfg.database.local "postgresql.service"
          ++ lib.optional cfg.cache.local "redis-plane.service"
          ++ lib.optional cfg.rabbitmq.local "rabbitmq.service";
        requires = [ "plane-migrate.service" ]
          ++ lib.optional cfg.database.local "postgresql.service"
          ++ lib.optional cfg.cache.local "redis-plane.service"
          ++ lib.optional cfg.rabbitmq.local "rabbitmq.service";

        serviceConfig = {
          Type = "exec";
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = cfg.stateDir;
          EnvironmentFile = "/etc/plane/plane.env";
          ExecStart = "${cfg.package}/bin/plane-api";
          Restart = "always";
          RestartSec = "5";

          # Security hardening
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ cfg.stateDir "/var/log/plane" ];
          NoNewPrivileges = true;

          # Load secrets
          LoadCredential = [
            "secret-key:${cfg.secretKeyFile}"
          ] ++ lib.optionals (cfg.database.passwordFile != null) [
            "db-password:${cfg.database.passwordFile}"
          ] ++ lib.optionals (cfg.rabbitmq.passwordFile != null) [
            "rabbitmq-password:${cfg.rabbitmq.passwordFile}"
          ] ++ lib.optionals (cfg.storage.credentialsFile != null) [
            "storage-credentials:${cfg.storage.credentialsFile}"
          ];
        };

        environment = {
          PORT = toString cfg.api.port;
          SECRET_KEY_FILE = "/run/credentials/plane-api/secret-key";
        } // lib.optionalAttrs (cfg.database.passwordFile != null) {
          POSTGRES_PASSWORD_FILE = "/run/credentials/plane-api/db-password";
        } // lib.optionalAttrs (cfg.rabbitmq.passwordFile != null) {
          RABBITMQ_PASSWORD_FILE = "/run/credentials/plane-api/rabbitmq-password";
        } // lib.optionalAttrs (cfg.storage.credentialsFile != null) {
          STORAGE_CREDENTIALS_FILE = "/run/credentials/plane-api/storage-credentials";
        };
      };

      # Celery worker service
      plane-worker = mkIf cfg.worker.enable {
        description = "Plane Celery worker";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" "plane-migrate.service" ]
          ++ lib.optional cfg.database.local "postgresql.service"
          ++ lib.optional cfg.cache.local "redis-plane.service"
          ++ lib.optional cfg.rabbitmq.local "rabbitmq.service";
        requires = [ "plane-migrate.service" ]
          ++ lib.optional cfg.database.local "postgresql.service"
          ++ lib.optional cfg.cache.local "redis-plane.service"
          ++ lib.optional cfg.rabbitmq.local "rabbitmq.service";

        serviceConfig = {
          Type = "exec";
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = cfg.stateDir;
          EnvironmentFile = "/etc/plane/plane.env";
          ExecStart = "${cfg.package}/bin/plane-worker";
          Restart = "always";
          RestartSec = "5";

          # Security hardening
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ cfg.stateDir "/var/log/plane" ];
          NoNewPrivileges = true;

          # Load secrets
          LoadCredential = [
            "secret-key:${cfg.secretKeyFile}"
          ] ++ lib.optionals (cfg.database.passwordFile != null) [
            "db-password:${cfg.database.passwordFile}"
          ] ++ lib.optionals (cfg.rabbitmq.passwordFile != null) [
            "rabbitmq-password:${cfg.rabbitmq.passwordFile}"
          ] ++ lib.optionals (cfg.storage.credentialsFile != null) [
            "storage-credentials:${cfg.storage.credentialsFile}"
          ];
        };

        environment = {
          SECRET_KEY_FILE = "/run/credentials/plane-worker/secret-key";
        } // lib.optionalAttrs (cfg.database.passwordFile != null) {
          POSTGRES_PASSWORD_FILE = "/run/credentials/plane-worker/db-password";
        } // lib.optionalAttrs (cfg.rabbitmq.passwordFile != null) {
          RABBITMQ_PASSWORD_FILE = "/run/credentials/plane-worker/rabbitmq-password";
        } // lib.optionalAttrs (cfg.storage.credentialsFile != null) {
          STORAGE_CREDENTIALS_FILE = "/run/credentials/plane-worker/storage-credentials";
        };
      };

      # Celery beat scheduler service
      plane-beat = mkIf cfg.beat.enable {
        description = "Plane Celery beat scheduler";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" "plane-migrate.service" ]
          ++ lib.optional cfg.database.local "postgresql.service"
          ++ lib.optional cfg.cache.local "redis-plane.service"
          ++ lib.optional cfg.rabbitmq.local "rabbitmq.service";
        requires = [ "plane-migrate.service" ]
          ++ lib.optional cfg.database.local "postgresql.service"
          ++ lib.optional cfg.cache.local "redis-plane.service"
          ++ lib.optional cfg.rabbitmq.local "rabbitmq.service";

        serviceConfig = {
          Type = "exec";
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = cfg.stateDir;
          EnvironmentFile = "/etc/plane/plane.env";
          ExecStart = "${cfg.package}/bin/plane-beat";
          Restart = "always";
          RestartSec = "5";

          # Security hardening
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ cfg.stateDir "/var/log/plane" ];
          NoNewPrivileges = true;

          # Load secrets
          LoadCredential = [
            "secret-key:${cfg.secretKeyFile}"
          ] ++ lib.optionals (cfg.database.passwordFile != null) [
            "db-password:${cfg.database.passwordFile}"
          ] ++ lib.optionals (cfg.rabbitmq.passwordFile != null) [
            "rabbitmq-password:${cfg.rabbitmq.passwordFile}"
          ] ++ lib.optionals (cfg.storage.credentialsFile != null) [
            "storage-credentials:${cfg.storage.credentialsFile}"
          ];
        };

        environment = {
          SECRET_KEY_FILE = "/run/credentials/plane-beat/secret-key";
        } // lib.optionalAttrs (cfg.database.passwordFile != null) {
          POSTGRES_PASSWORD_FILE = "/run/credentials/plane-beat/db-password";
        } // lib.optionalAttrs (cfg.rabbitmq.passwordFile != null) {
          RABBITMQ_PASSWORD_FILE = "/run/credentials/plane-beat/rabbitmq-password";
        } // lib.optionalAttrs (cfg.storage.credentialsFile != null) {
          STORAGE_CREDENTIALS_FILE = "/run/credentials/plane-beat/storage-credentials";
        };
      };

      # Frontend services
      # Web interface service
      plane-web = mkIf cfg.web.enable {
        description = "Plane web interface";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ] ++ lib.optional cfg.api.enable "plane-api.service";
        wants = lib.optional cfg.api.enable "plane-api.service";

        serviceConfig = {
          Type = "exec";
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = "${cfg.package}/share/plane-web";
          ExecStart = "${cfg.package}/bin/plane-web";
          Restart = "always";
          RestartSec = "5";

          # Security hardening
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ "/var/log/plane" ];
          NoNewPrivileges = true;
        };

        environment = {
          PORT = toString cfg.web.port;
          NEXT_PUBLIC_API_BASE_URL = "https://${cfg.domain}/api";
          NEXT_PUBLIC_WEB_BASE_URL = "https://${cfg.domain}";
          NEXT_PUBLIC_SPACE_BASE_URL = "https://${cfg.domain}/spaces";
          NEXT_PUBLIC_ADMIN_BASE_URL = "https://${cfg.domain}/god-mode";
        };
      };

      # Admin interface service
      plane-admin = mkIf cfg.admin.enable {
        description = "Plane admin interface";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ] ++ lib.optional cfg.api.enable "plane-api.service";
        wants = lib.optional cfg.api.enable "plane-api.service";

        serviceConfig = {
          Type = "exec";
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = "${cfg.package}/share/plane-admin";
          ExecStart = "${cfg.package}/bin/plane-admin";
          Restart = "always";
          RestartSec = "5";

          # Security hardening
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ "/var/log/plane" ];
          NoNewPrivileges = true;
        };

        environment = {
          PORT = toString cfg.admin.port;
          NEXT_PUBLIC_API_BASE_URL = "https://${cfg.domain}/api";
          NEXT_PUBLIC_WEB_BASE_URL = "https://${cfg.domain}";
          NEXT_PUBLIC_SPACE_BASE_URL = "https://${cfg.domain}/spaces";
          NEXT_PUBLIC_ADMIN_BASE_URL = "https://${cfg.domain}/god-mode";
        };
      };

      # Space interface service
      plane-space = mkIf cfg.space.enable {
        description = "Plane public space interface";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ] ++ lib.optional cfg.api.enable "plane-api.service";
        wants = lib.optional cfg.api.enable "plane-api.service";

        serviceConfig = {
          Type = "exec";
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = "${cfg.package}/share/plane-space";
          ExecStart = "${cfg.package}/bin/plane-space";
          Restart = "always";
          RestartSec = "5";

          # Security hardening
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ "/var/log/plane" ];
          NoNewPrivileges = true;
        };

        environment = {
          PORT = toString cfg.space.port;
          NEXT_PUBLIC_API_BASE_URL = "https://${cfg.domain}/api";
          NEXT_PUBLIC_WEB_BASE_URL = "https://${cfg.domain}";
          NEXT_PUBLIC_SPACE_BASE_URL = "https://${cfg.domain}/spaces";
          NEXT_PUBLIC_ADMIN_BASE_URL = "https://${cfg.domain}/god-mode";
        };
      };

      # Live collaboration service
      plane-live = mkIf cfg.live.enable {
        description = "Plane live collaboration service";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ] ++ lib.optional cfg.api.enable "plane-api.service";
        wants = lib.optional cfg.api.enable "plane-api.service";

        serviceConfig = {
          Type = "exec";
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = "${cfg.package}/share/plane-live";
          ExecStart = "${cfg.package}/bin/plane-live";
          Restart = "always";
          RestartSec = "5";

          # Security hardening
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ "/var/log/plane" ];
          NoNewPrivileges = true;
        };

        environment = {
          PORT = toString cfg.live.port;
          NEXT_PUBLIC_API_BASE_URL = "https://${cfg.domain}/api";
          NEXT_PUBLIC_WEB_BASE_URL = "https://${cfg.domain}";
          NEXT_PUBLIC_SPACE_BASE_URL = "https://${cfg.domain}/spaces";
          NEXT_PUBLIC_ADMIN_BASE_URL = "https://${cfg.domain}/god-mode";
        };
      };
    };

    # Nginx reverse proxy configuration
    services.nginx = mkIf cfg.nginx.enable {
      enable = true;

      virtualHosts.${cfg.domain} = {
        enableACME = cfg.acme.enable;
        forceSSL = cfg.acme.enable;

        locations = {
          # API backend
          "/api/" = mkIf cfg.api.enable {
            proxyPass = "http://127.0.0.1:${toString cfg.api.port}/";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_buffering off;
            '';
          };

          # Admin interface (god-mode)
          "/god-mode/" = mkIf cfg.admin.enable {
            proxyPass = "http://127.0.0.1:${toString cfg.admin.port}/";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };

          # Public spaces
          "/spaces/" = mkIf cfg.space.enable {
            proxyPass = "http://127.0.0.1:${toString cfg.space.port}/";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };

          # Live collaboration service
          "/collaboration/" = mkIf cfg.live.enable {
            proxyPass = "http://127.0.0.1:${toString cfg.live.port}/";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
            '';
          };

          # Static files served by backend
          "/media/" = mkIf cfg.api.enable {
            proxyPass = "http://127.0.0.1:${toString cfg.api.port}/media/";
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };

          "/static/" = mkIf cfg.api.enable {
            proxyPass = "http://127.0.0.1:${toString cfg.api.port}/static/";
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };

          # Main web interface (default/catch-all)
          "/" = mkIf cfg.web.enable {
            proxyPass = "http://127.0.0.1:${toString cfg.web.port}/";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };
        };

        extraConfig = ''
          client_max_body_size 5M;
        '';
      };
    };

    # ACME configuration for SSL certificates
    security.acme = mkIf cfg.acme.enable {
      acceptTerms = true;
      defaults.email = lib.mkDefault "admin@${cfg.domain}";
    };
  };
}

{ lib
, config
, ...
}:
let
  inherit (lib) mkIf;
  cfg = config.services.plane;
in
{
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
      "d ${cfg.logDir} 0750 ${cfg.user} ${cfg.group} -"
      "d /etc/plane 0755 root root -"
    ];

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
        PGDATABASE=${lib.optional (! cfg.database.local) cfg.database.name}
        POSTGRES_DB=${cfg.database.name}
        POSTGRES_PORT=${toString cfg.database.port}
        ${lib.optional (cfg.database.local) "PGDATA=${cfg.stateDir}/postgres"}

        # Redis Configuration
        REDIS_HOST=${cfg.cache.host}
        REDIS_PORT=${toString cfg.cache.port}

        # RabbitMQ Configuration
        RABBITMQ_HOST=${cfg.rabbitmq.host}
        RABBITMQ_PORT=${toString cfg.rabbitmq.port}
        RABBITMQ_USER=${cfg.rabbitmq.user}
        RABBITMQ_VHOST=${cfg.rabbitmq.vhost}

        # API Configuration
        GUNICORN_WORKERS=${toString cfg.api.workers}
        API_KEY_RATE_LIMIT=60/minute
        
        # Logging Configuration
        PLANE_LOG_DIR=${cfg.logDir}

        # Service URLs
        NEXT_PUBLIC_API_BASE_URL=https://${cfg.domain}/api
        NEXT_PUBLIC_WEB_BASE_URL=https://${cfg.domain}
        NEXT_PUBLIC_SPACE_BASE_URL=https://${cfg.domain}/spaces
        NEXT_PUBLIC_ADMIN_BASE_URL=https://${cfg.domain}/god-mode
        
        # Sentry (optional)
        SENTRY_DSN=""
        
        # Scout APM (optional)
        SCOUT_MONITOR=0
        SCOUT_KEY=""
      '' +
      (if cfg.storage.local then ''
        # Data Storage Configuration
        USE_MINIO=1
        MINIO_ROOT_USER=${cfg.storage.accessKey}
        MINIO_ROOT_PASSWORD=${cfg.storage.secretKey}
        BUCKET_NAME=${cfg.storage.bucket}
        FILE_SIZE_LIMIT=5242880
      '' else ''
        # Data Storage Configuration
        USE_MINIO=0
        FILE_SIZE_LIMIT=5242880
        AWS_REGION=${cfg.storage.region}
        AWS_ACCESS_KEY_ID=${cfg.storage.accessKey}
        AWS_SECRET_ACCESS_KEY=${cfg.storage.secretKey}
        AWS_S3_ENDPOINT_URL=${cfg.storage.protocol}://${cfg.storage.host}:${toString cfg.storage.port}
        AWS_S3_BUCKET_NAME=${cfg.storage.bucket}
      '') +
      mkIf cfg.email.enable ''
        EMAIL_HOST=${cfg.email.host}
        EMAIL_PORT=${toString cfg.email.port}
        EMAIL_USE_TLS=${if cfg.email.useTLS then "1" else "0"}
      '';
    };

    # Secret credentials environment file from secret files
    system.activationScripts.plane-credentials = ''
      # Create credentials environment file from secret files
      touch /etc/plane/credentials.env
      chmod 640 /etc/plane/credentials.env
      chown ${cfg.user}:${cfg.group} /etc/plane/credentials.env

      # Django secret key
      echo "SECRET_KEY=$(cat ${cfg.secretKeyFile})" > /etc/plane/credentials.env

      # Database password if configured
      ${lib.optionalString (cfg.database.passwordFile != null) ''
        echo "POSTGRES_USER=${cfg.database.user}" >> /etc/plane/credentials.env
        echo "POSTGRES_PASSWORD=$(cat ${cfg.database.passwordFile})" >> /etc/plane/credentials.env
        echo "DATABASE_URL=postgresql://${cfg.database.user}:$(cat ${cfg.database.passwordFile})@${cfg.database.host}:${toString cfg.database.port}/${cfg.database.name}" >> /etc/plane/credentials.env
      ''}

      # RabbitMQ password if configured
      ${lib.optionalString (cfg.rabbitmq.passwordFile != null) ''
        echo "RABBITMQ_PASSWORD=$(cat ${cfg.rabbitmq.passwordFile})" >> /etc/plane/credentials.env
        echo "AMQP_URL=amqp://${cfg.rabbitmq.user}:$(cat ${cfg.rabbitmq.passwordFile})@${cfg.rabbitmq.host}:${toString cfg.rabbitmq.port}/${cfg.rabbitmq.vhost}" >> /etc/plane/credentials.env
      ''}

      # S3 credentials if configured
      ${lib.optionalString (!cfg.storage.local && cfg.storage.credentialsFile != null) ''
        AWS_ACCESS_KEY_ID=$(head -n 1 ${cfg.storage.credentialsFile})
        AWS_SECRET_ACCESS_KEY=$(tail -n 1 ${cfg.storage.credentialsFile})
        echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> /etc/plane/credentials.env
        echo "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> /etc/plane/credentials.env
      ''}
    '';
  };
}

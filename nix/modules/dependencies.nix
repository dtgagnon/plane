{ lib
, pkgs
, config
, ...
}:
let
  inherit (lib) mkIf;
  cfg = config.services.plane;
in
{
  config = mkIf cfg.enable {
    # Conditional service dependencies
    # These leverage existing NixOS modules for battle-tested configurations
    services.postgresql = mkIf cfg.database.local {
      enable = true;
      dataDir = "${cfg.dataDir}";
      settings.port = cfg.database.port;
      ensureDatabases = [ cfg.database.name ];
      ensureUsers = [
        {
          name = cfg.database.user;
          ensureDBOwnership = true;
        }
      ];
    };
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 postgres postgres -"
    ];
    # Set the postgresql password on every start to ensure it's always in sync.
    systemd.services.postgresql.serviceConfig.postStart = mkIf cfg.database.local ''
      ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql_16}/bin/psql -c "ALTER USER ${cfg.database.user} WITH PASSWORD '$(cat ${cfg.database.passwordFile})'"
    '';

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
      dataDir = [ "/srv/plane/minio" ]; # Stores data within plane stateDir for organization
      configDir = "/var/lib/minio/config";
      rootCredentialsFile = cfg.storage.credentialsFile;
    };
  };
}

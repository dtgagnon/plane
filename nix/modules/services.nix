{ config, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.services.plane;
in
{
  config = mkIf cfg.enable {
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
        requires = [ "network.target" ]
          ++ lib.optional cfg.database.local "postgresql.service"
          ++ lib.optional cfg.cache.local "redis-plane.service"
          ++ lib.optional cfg.rabbitmq.local "rabbitmq.service";
        serviceConfig = {
          Type = "oneshot";
          User = cfg.user;
          Group = cfg.group;
          EnvironmentFile = [
            "/etc/plane/plane.env"
            "/etc/plane/credentials.env"
          ];
          WorkingDirectory = "/tmp";
          ExecStart = "${cfg.package}/bin/plane migrate";
          Restart = "no";
        };
      };

      # API server
      plane-api = mkIf cfg.api.enable {
        description = "Plane API server";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" "plane-migrate.service" ]
          ++ lib.optional cfg.database.local "postgresql.service"
          ++ lib.optional cfg.cache.local "redis-plane.service"
          ++ lib.optional cfg.rabbitmq.local "rabbitmq.service"
          ++ lib.optional cfg.storage.local "minio.service";
        wants = [ "plane-migrate.service" ]
          ++ lib.optional cfg.storage.local "minio.service";
        requires = [ "network.target" ]
          ++ lib.optional cfg.database.local "postgresql.service"
          ++ lib.optional cfg.cache.local "redis-plane.service"
          ++ lib.optional cfg.rabbitmq.local "rabbitmq.service";
        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;
          EnvironmentFile = [
            "/etc/plane/plane.env"
            "/etc/plane/credentials.env"
          ];
          WorkingDirectory = "/tmp";
          ExecStart = "${cfg.package}/bin/plane api --bind 127.0.0.1:${toString cfg.api.port}";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      # Celery worker
      plane-worker = mkIf cfg.worker.enable {
        description = "Plane Celery worker";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" "plane-migrate.service" ]
          ++ lib.optional cfg.database.local "postgresql.service"
          ++ lib.optional cfg.cache.local "redis-plane.service"
          ++ lib.optional cfg.rabbitmq.local "rabbitmq.service"
          ++ lib.optional cfg.storage.local "minio.service";
        wants = [ "plane-migrate.service" ]
          ++ lib.optional cfg.storage.local "minio.service";
        requires = [ "network.target" ]
          ++ lib.optional cfg.database.local "postgresql.service"
          ++ lib.optional cfg.cache.local "redis-plane.service"
          ++ lib.optional cfg.rabbitmq.local "rabbitmq.service";
        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;
          EnvironmentFile = [
            "/etc/plane/plane.env"
            "/etc/plane/credentials.env"
          ];
          WorkingDirectory = "/tmp";
          ExecStart = "${cfg.package}/bin/plane worker";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      # Celery beat scheduler
      plane-beat = mkIf cfg.beat.enable {
        description = "Plane Celery beat scheduler";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" "plane-migrate.service" ]
          ++ lib.optional cfg.database.local "postgresql.service"
          ++ lib.optional cfg.cache.local "redis-plane.service"
          ++ lib.optional cfg.rabbitmq.local "rabbitmq.service";
        wants = [ "plane-migrate.service" ];
        requires = [ "network.target" ]
          ++ lib.optional cfg.database.local "postgresql.service"
          ++ lib.optional cfg.cache.local "redis-plane.service"
          ++ lib.optional cfg.rabbitmq.local "rabbitmq.service";
        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;
          EnvironmentFile = [
            "/etc/plane/plane.env"
            "/etc/plane/credentials.env"
          ];
          WorkingDirectory = "/tmp";
          ExecStart = "${cfg.package}/bin/plane beat";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      # Web frontend
      plane-web = mkIf cfg.web.enable {
        description = "Plane web interface";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ] ++ lib.optional cfg.api.enable "plane-api.service";
        wants = lib.optional cfg.api.enable "plane-api.service";
        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;
          EnvironmentFile = [
            "/etc/plane/plane.env"
          ];
          WorkingDirectory = "/tmp";
          ExecStart = "${cfg.package}/bin/plane web --port ${toString cfg.web.port}";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      # Admin frontend
      plane-admin = mkIf cfg.admin.enable {
        description = "Plane admin interface";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ] ++ lib.optional cfg.api.enable "plane-api.service";
        wants = lib.optional cfg.api.enable "plane-api.service";
        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;
          EnvironmentFile = [
            "/etc/plane/plane.env"
          ];
          WorkingDirectory = "/tmp";
          ExecStart = "${cfg.package}/bin/plane admin --port ${toString cfg.admin.port}";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      # Space frontend
      plane-space = mkIf cfg.space.enable {
        description = "Plane space interface";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ] ++ lib.optional cfg.api.enable "plane-api.service";
        wants = lib.optional cfg.api.enable "plane-api.service";
        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;
          EnvironmentFile = [
            "/etc/plane/plane.env"
          ];
          WorkingDirectory = "/tmp";
          ExecStart = "${cfg.package}/bin/plane space --port ${toString cfg.space.port}";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      # Live collaboration service
      plane-live = mkIf cfg.live.enable {
        description = "Plane live collaboration service";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ] ++ lib.optional cfg.api.enable "plane-api.service";
        wants = lib.optional cfg.api.enable "plane-api.service";
        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;
          EnvironmentFile = [
            "/etc/plane/plane.env"
          ];
          WorkingDirectory = "/tmp";
          ExecStart = "${cfg.package}/bin/plane live --port ${toString cfg.live.port}";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
    };
  };
}

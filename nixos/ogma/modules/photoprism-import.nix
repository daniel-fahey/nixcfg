{ config, ... }:

let
  cfg = config.services.photoprism;
  env = {
    PHOTOPRISM_ORIGINALS_PATH = cfg.originalsPath;
    PHOTOPRISM_IMPORT_PATH = cfg.importPath;
  };
in {
  systemd.services.photoprism-import = {
    description = "PhotoPrism Import Service";
    requires = [ "photoprism.service" ];
    after = [ "photoprism.service" ];
    serviceConfig = {
      Type = "simple";
      User = "photoprism";
      Group = "photoprism";
      ExecStart = "${cfg.package}/bin/photoprism import ${cfg.importPath}";
      Restart = "no";
      RuntimeMaxSec = "infinity";
    };
    environment = env;
    startLimitIntervalSec = 0;
  };

  systemd.timers.photoprism-import = {
    description = "Schedule PhotoPrism Import Service";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitInactiveSec = "1m";
      AccuracySec = "1s";
    };
  };
}
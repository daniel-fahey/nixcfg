{ config, pkgs, secrets, ... }:

{
  sops.secrets."nextcloud/admin_password" = {
    owner = "nextcloud";
    group = "nextcloud";
    # restartUnits = [ "nextcloud.service" ];
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud30;
    hostName = "cloud.${secrets.ogma.domain}";
    https = true;
    database.createLocally = true;
    config = {
      dbtype = "pgsql";
      adminpassFile = config.sops.secrets."nextcloud/admin_password".path;
    };
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
      memories cospend deck calendar contacts tasks notes polls spreed
      registration # N.B. enabled
      # recently available in pkgs.nextcloud30:
      maps forms;
    };
    extraAppsEnable = true;
    configureRedis = true;
  };

  services.nginx.virtualHosts."${config.services.nextcloud.hostName}" = {
    forceSSL = true;
    useACMEHost = secrets.ogma.domain;
  };
  

}
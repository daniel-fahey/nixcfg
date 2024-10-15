{ config, pkgs, secrets, ... }:

{
  sops.secrets."nextcloud/admin_password" = {
    owner = "nextcloud";
    group = "nextcloud";
    # restartUnits = [ "nextcloud.service" ];
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud29;
    hostName = "cloud.${secrets.ogma.additional_domain}";
    https = true;
    database.createLocally = true;
    config = {
      dbtype = "pgsql";
      adminpassFile = config.sops.secrets."nextcloud/admin_password".path;
    };
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
      memories cospend deck calendar contacts tasks notes polls spreed
      # registration # disabled
      # missing from pkgs.nextcloud30, but available in pkgs.nextcloud29:
      maps forms;
    };
    extraAppsEnable = true;
    configureRedis = true;
  };

  services.nginx.virtualHosts."${config.services.nextcloud.hostName}" = {
    forceSSL = true;
    useACMEHost = secrets.ogma.additional_domain;
  };
  

}
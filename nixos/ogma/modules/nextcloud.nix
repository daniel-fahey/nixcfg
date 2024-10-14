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
    hostName = "cloud.${secrets.ogma.additional_domain}";
    https = true;
    database.createLocally = true;
    config = {
      dbtype = "pgsql";
      adminpassFile = config.sops.secrets."nextcloud/admin_password".path;
    };
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
      memories cospend deck calendar contacts tasks notes polls registration spreed;
      # maps forms # missing from pkgs.nextcloud30, but available in pkgs.nextcloud29
    };
    extraAppsEnable = true;
    configureRedis = true;
  };

  services.nginx.virtualHosts."${config.services.nextcloud.hostName}" = {
    forceSSL = true;
    enableACME = true;
  };
  

}
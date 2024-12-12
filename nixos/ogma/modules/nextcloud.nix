{ config, pkgs, secrets, ... }:

{
  sops.secrets."nextcloud/admin_password" = {
    owner = "nextcloud";
    group = "nextcloud";
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
      # Collabora configuration
      overwriteProtocol = "https";
      extraTrustedDomains = [
        "office.${secrets.ogma.domain}"
      ];
    };
    settings.loglevel = 0;
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
        memories cospend deck calendar contacts tasks notes polls spreed
        registration maps forms richdocuments;
    };
    extraAppsEnable = true;
    configureRedis = true;
  };

  services.nginx.virtualHosts."${config.services.nextcloud.hostName}" = {
    forceSSL = true;
    useACMEHost = secrets.ogma.domain;
  };
}
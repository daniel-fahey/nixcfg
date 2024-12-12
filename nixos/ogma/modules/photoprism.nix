{ config, secrets, pkgs, ... }:

{
  sops.secrets."photoprism/admin_password" = {
    owner = "photoprism";
    group = "photoprism";
    restartUnits = [ "photoprism.service" ];
  };

  users.users.photoprism = {
    isSystemUser = true;
    group = "photoprism";
    description = "PhotoPrism service user";
  };

  users.groups.photoprism = {};

  users.groups.media.members = [ "syncthing" "photoprism" ];

  systemd.tmpfiles.rules = [
    "d /persist/media 2770 root media - -"
    "d /persist/media/photoprism 2770 root media - -"
    "d /persist/media/photoprism/originals 2770 root media - -"
  ];

  services.photoprism = {
    enable = true;
    address = "[::1]";
    # port = 2342; # default
    passwordFile = config.sops.secrets."photoprism/admin_password".path;

    originalsPath = "/persist/media/photoprism/originals";
    importPath = "/persist/media/photoprism/import";
    # storagePath = "/var/lib/photoprism"; # default

    settings = {
      PHOTOPRISM_ADMIN_USER = "admin";
      PHOTOPRISM_DEFAULT_LOCALE = "en";
      PHOTOPRISM_SITE_URL = "https://photos.${secrets.ogma.additional_domain}";
      PHOTOPRISM_DISABLE_TLS = "true";
      PHOTOPRISM_DATABASE_DRIVER = "mysql";
      PHOTOPRISM_DATABASE_NAME = "photoprism";
      PHOTOPRISM_DATABASE_SERVER = "/run/mysqld/mysqld.sock";
      PHOTOPRISM_DATABASE_USER = "photoprism";
      PHOTOPRISM_INDEX_SCHEDULE = "*/10 * * * *"; # At every 10th minute
      PHOTOPRISM_ORIGINALS_LIMIT = "-1";
    };
  };

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureDatabases = [ "photoprism" ];
    ensureUsers = [ {
      name = "photoprism";
      ensurePermissions = {
        "photoprism.*" = "ALL PRIVILEGES";
      };
    } ];
  };

  services.nginx = {
    virtualHosts."photos.${secrets.ogma.additional_domain}" = {
      forceSSL = true;
      enableACME = true;
      listenAddresses = [
        "${secrets.ogma.additional_ipv4_address}"
      ];
      locations."/" = {
        proxyPass = "http://[::1]:2342";
        proxyWebsockets = true;
      };
    };
  };

}


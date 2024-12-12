{ config, pkgs, secrets, ... }:

{
  services.collabora-online = {
    enable = true;

    settings = {
      ssl.enable = false;
      ssl.termination = true;

      net = {
        listen = "loopback";
        post_allow.host = [ "::1" ];
      };

      storage.wopi = {
        "@allow" = true;
        host = [ "cloud.${secrets.ogma.domain}" ];
      };
    };
  };

  services.nginx.virtualHosts."office.${secrets.ogma.domain}" = let
    proxyPass = "http://[::1]:${toString config.services.collabora-online.port}";
  in {
    forceSSL = true;
    useACMEHost = secrets.ogma.domain;

    locations = {
      "^~ /browser" = {
        inherit proxyPass;
        proxyWebsockets = true;
      };

      "^~ /hosting/discovery" = {
        inherit proxyPass;
      };

      "^~ /hosting/capabilities" = {
        inherit proxyPass;
      };

      "~ ^/cool/(.*)/ws$" = {
        inherit proxyPass;
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "Upgrade";
          proxy_read_timeout 36000s;
        '';
      };

      "~ ^/(c|l)ool" = {
        inherit proxyPass;
        priority = 1001;
      };

      "^~ /cool/adminws" = {
        inherit proxyPass;
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "Upgrade";
          proxy_read_timeout 36000s;
        '';
      };
    };
  };
}
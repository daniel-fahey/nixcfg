{ config, lib, pkgs, ... }:

let
  cfg = config.services.stalwart;
in {
  options.services.stalwart = {
    enable = lib.mkEnableOption "Stalwart mail server";
    
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain name for the mail server";
    };

    ipv4 = lib.mkOption {
      type = lib.types.str;
      description = "IPv4 address to bind services to";
    };

    ipv6 = lib.mkOption {
      type = lib.types.str;
      description = "IPv6 address to bind services to";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."stalwart/admin-secret" = {
      owner = "stalwart-mail";
      group = "stalwart-mail";
      restartUnits = [ "stalwart-mail.service" ];
    };

    services.stalwart-mail = {
      enable = true;
      package = pkgs.stalwart-mail;
      openFirewall = false;
      settings = {
        queue.outbound.tls.mta-sts = "optional";
        session.mta-sts = {
          mode = "testing";
          max-age = "7d";
          mx = [ "mail.${cfg.domain}" ];
        };
        server = {
          hostname = "mail.${cfg.domain}";
          tls.enable = true;
          listener = {
            smtp = {
              bind = [ "${cfg.ipv4}:25" "[${cfg.ipv6}]:25" ];
              protocol = "smtp";
            };
            submissions = {
              bind = [ "${cfg.ipv4}:465" "[${cfg.ipv6}]:465" ];
              protocol = "smtp";
              tls.implicit = true;
            };
            imaps = {
              bind = [ "${cfg.ipv4}:993" "[${cfg.ipv6}]:993" ];
              protocol = "imap";
              tls.implicit = true;
            };
            https = {
              bind = "[::1]:18080";
              protocol = "http";
            };
          };
        };
        lookup.default = {
          hostname = "mail.${cfg.domain}";
          domain = cfg.domain;
        };
        authentication.fallback-admin = {
          user = "admin";
          secret = "%{file:${config.sops.secrets."stalwart/admin-secret".path}}%";
        };
        certificate."default" = {
          cert = "%{file:/var/lib/acme/mail.${cfg.domain}/fullchain.pem}%";
          private-key = "%{file:/var/lib/acme/mail.${cfg.domain}/key.pem}%";
          default = true;
        };
      };
    };

    services.nginx = {
      virtualHosts = {
        "mail.${cfg.domain}" = {
          forceSSL = true;
          enableACME = true;
          listenAddresses = [ cfg.ipv4 "[${cfg.ipv6}]" ];
          serverAliases = [
            "mta-sts.${cfg.domain}"
            "autoconfig.${cfg.domain}" 
            "autodiscover.${cfg.domain}"
          ];
          locations."/" = {
            proxyPass = "http://[::1]:18080";
            proxyWebsockets = true;
          };
        };
        };
      };

    networking.firewall.allowedTCPPorts = [ 25 465 993 ];
    users.users.stalwart-mail.extraGroups = [ config.services.nginx.group ];
  };
}

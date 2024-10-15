{ config, pkgs, secrets, ... }:

let
  stalwartSecrets = [
    "admin-secret"
  ];
  additionalDomain = secrets.ogma.additional_domain;
  additionalIP = secrets.ogma.additional_ipv4_address;
in
{
  sops.secrets = builtins.listToAttrs (map (name: {
    name = "stalwart/${name}";
    value = {
      owner = "stalwart-mail";
      group = "stalwart-mail";
      restartUnits = [ "stalwart-mail.service" ];
    };
  }) stalwartSecrets);

  services.stalwart-mail = {
    enable = true;
    package = pkgs.stalwart-mail;
    openFirewall = false;
    settings = {
      server = {
        hostname = "mx1.${additionalDomain}";
        tls = {
          enable = true;
        };
        listener = {
          submissions = {
            bind = "${additionalIP}:465";
            protocol = "smtp";
            tls.implicit = true;
          };
          imaps = {
            bind = "${additionalIP}:993";
            protocol = "imap";
            tls.implicit = true;
          };
          http = {
            bind = "[::1]:18080";
            protocol = "http";
          };
        };
      };
      lookup.default = {
        hostname = "mx1.${additionalDomain}";
        domain = additionalDomain;
      };
      authentication.fallback-admin = {
        user = "admin";
        secret = "%{file:${config.sops.secrets."stalwart/admin-secret".path}}%";
      };
      certificate."default" = {
        cert = "%{file:/var/lib/acme/${additionalDomain}/fullchain.pem}%";
        private-key = "%{file:/var/lib/acme/${additionalDomain}/key.pem}%";
        default = true;
      };
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts = {
      "webadmin.${additionalDomain}" = {
        forceSSL = true;
        useACMEHost = "${additionalDomain}";
        serverAliases = [
          "mx1.${additionalDomain}"
          "mail.${additionalDomain}"
          "mta-sts.${additionalDomain}"
          "autoconfig.${additionalDomain}"
          "autodiscover.${additionalDomain}"
        ];
        locations."/" = {
          proxyPass = "http://[::1]:18080";
          proxyWebsockets = true;
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    465  # For SMTPS
    993  # For IMAPS
  ];

  # Ensure Stalwart can read the ACME certificates
  users.users.stalwart-mail.extraGroups = [ config.services.nginx.group ];
}
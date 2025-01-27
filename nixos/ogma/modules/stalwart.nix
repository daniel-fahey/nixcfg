{ config, pkgs, secrets, ... }:

let
  stalwartSecrets = [
    "admin-secret"
  ];
  domain = secrets.ogma.domain;
  ipv4 = secrets.ogma.ipv4_address;
  ipv6 = secrets.ogma.ipv6_address;
  
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
      queue.outbound.tls.mta-sts = "optional";
      session.mta-sts = {
        mode = "testing";
        max-age = "7d";
        mx = [ "mx1.${domain}" ];
      };
      server = {
        hostname = "mx1.${domain}";
        tls = {
          enable = true;
        };
        listener = {
          smtp = {
            bind = [ "${ipv4}:25" "[${ipv6}1]:25" ];
            protocol = "smtp";
          };
          submissions = {
            bind = [ "${ipv4}:465" "[${ipv6}1]:465" ];
            protocol = "smtp";
            tls.implicit = true;
          };
          imaps = {
            bind = [ "${ipv4}:993" "[${ipv6}1]:993" ];
            protocol = "imap";
            tls.implicit = true;
          };
          https = {
            bind = "[::1]:18080";
            # bind = [ "${ipv4}:443" "[${ipv6}1]:443" ];
            protocol = "http";
            # tls.implicit = true;
          };
        };
      };
      lookup.default = {
        hostname = "mx1.${domain}";
        domain = domain;
      };
      authentication.fallback-admin = {
        user = "admin";
        secret = "%{file:${config.sops.secrets."stalwart/admin-secret".path}}%";
      };
      certificate."default" = {
        cert = "%{file:/var/lib/acme/${domain}/fullchain.pem}%";
        private-key = "%{file:/var/lib/acme/${domain}/key.pem}%";
        default = true;
      };
    };
  };

  services.nginx = {
    virtualHosts = {
      "webadmin.${domain}" = {
        forceSSL = true;
        useACMEHost = "${domain}";
        listenAddresses = [
          "${secrets.ogma.ipv4_address}"
        ];
        serverAliases = [
          "mx1.${domain}"
          "mail.${domain}"
          "mta-sts.${domain}"
          "autoconfig.${domain}"
          "autodiscover.${domain}"
        ];
        locations."/" = {
          proxyPass = "http://[::1]:18080";
          proxyWebsockets = true;
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    25   # For SMTP
    465  # For SMTPS
    993  # For IMAPS
  ];

  # Ensure Stalwart can read the ACME certificates
  users.users.stalwart-mail.extraGroups = [ config.services.nginx.group ];
}
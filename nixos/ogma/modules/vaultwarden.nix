{ config, secrets, ... }:
{

  services.vaultwarden = {
    enable = true;
    environmentFile = config.sops.secrets."vaultwarden.env".path;
    config = {
      ROCKET_ADDRESS = "::1";
      ROCKET_PORT = 8222;
      DOMAIN = "https://vault.${secrets.ogma.additional_domain}";
      SIGNUPS_ALLOWED = false;
    };
    backupDir = "/var/backup/vaultwarden";
  };

  services.nginx = {
    virtualHosts."vault.${secrets.ogma.additional_domain}" = {
      forceSSL = true;
      enableACME = true;
      listenAddresses = [
        "${secrets.ogma.additional_ipv4_address}"
      ];
      locations."/" = {
        proxyPass = "http://[::1]:8222";
      };
    };
  };

  sops.secrets."vaultwarden.env" = {
    format = "dotenv";
    owner = "vaultwarden";
    group = "vaultwarden";
    sopsFile = ../vaultwarden.env;
    restartUnits = [ "vaultwarden.service" ];
  };

  services.fail2ban.jails = {
    vaultwarden-auth = {
      settings = {
        enabled = true;
        port = "http,https";
        filter = "vaultwarden-auth";
        backend = "systemd";
        maxretry = 3;
        bantime = "1h";
        action = "iptables-multiport[name=HTTP, port=\"http,https\"]";
      };
    };
  };

  environment.etc."fail2ban/filter.d/vaultwarden-auth.conf".text = ''
    [Definition]
    failregex = ^.*(Username or password is incorrect\. Try again|Invalid admin token)\. IP: <HOST>.*$
  '';
}

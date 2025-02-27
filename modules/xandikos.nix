{ config, facts, ... }:
{

  services.xandikos = {
    enable = true;
    extraOptions = [
      "--defaults"
      "--current-user-principal" "/user/"
    ];
    nginx = {
      enable = true;
      hostName = "dav.${facts.ogma.additional_domain}";
    };
  };

  services.nginx = {
    virtualHosts."dav.${facts.ogma.additional_domain}" = {
      forceSSL = true;
      enableACME = true;
      basicAuthFile = config.sops.secrets.dav_htpasswd.path;
      listenAddresses = [
        "${facts.ogma.additional_ipv4_address}"
      ];
    };
  };

  sops.secrets.dav_htpasswd = {
    owner = "nginx";
    group = "nginx";
    restartUnits = [ "nginx.service" ];
  };

  services.fail2ban.jails = {
    nginx-basic-auth = {
      settings = {
        enabled = true;
        port = "http,https";
        filter = "nginx-http-auth";
        backend = "systemd";
        maxretry = 3;
        bantime = "1h";
        action = "iptables-multiport[name=HTTP, port=\"http,https\"]";
      };
    };
  };

}

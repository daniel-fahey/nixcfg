{ config, secrets, ... }:
{

  services.xandikos = {
    enable = true;
    extraOptions = [
      "--defaults"
      "--current-user-principal" "/user/"
    ];
    nginx = {
      enable = true;
      hostName = "dav.${secrets.ogma.additional_domain}";
    };
  };

  services.nginx = {
    virtualHosts."dav.${secrets.ogma.additional_domain}" = {
      forceSSL = true;
      enableACME = true;
      basicAuthFile = config.sops.secrets.dav_htpasswd.path;
      listenAddresses = [
        "${secrets.ogma.additional_ipv4_address}"
      ];
    };
  };

  sops.secrets.dav_htpasswd = {
    owner = "nginx";
    group = "nginx";
    sopsFile = ../secrets.yaml;
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

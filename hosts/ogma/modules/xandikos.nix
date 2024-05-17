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
      hostName = "dav.${secrets.ogma.domain}";
    };
  };

  services.nginx = {
    virtualHosts."dav.${secrets.ogma.domain}" = {
      forceSSL = true;
      enableACME = true;
      basicAuthFile = config.sops.secrets.dav_htpasswd.path;
    };
  };

  sops.secrets.dav_htpasswd = {
    owner = "nginx";
    group = "nginx";
    sopsFile = ../secrets.yaml;
    restartUnits = [ "nginx.service" ];
  };

}

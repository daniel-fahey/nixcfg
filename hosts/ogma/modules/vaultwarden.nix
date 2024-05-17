{ config, secrets, ... }:
{

  services.vaultwarden = {
    enable = true;
    environmentFile = config.sops.secrets."vaultwarden.env".path;
    config = {
      ROCKET_ADDRESS = "::1";
      ROCKET_PORT = 8222;
      DOMAIN = "https://vault.${secrets.ogma.domain}";
      SIGNUPS_ALLOWED = false;
    };
  };

  services.nginx = {
    virtualHosts."vault.${secrets.ogma.domain}" = {
      forceSSL = true;
      enableACME = true;
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

}

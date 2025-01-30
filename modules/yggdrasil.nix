{ config, secrets, ... }:
{

  services.yggdrasil = {
    enable = true;
    configFile = config.sops.secrets."yggdrasil.hjson".path;
  };

  sops.secrets."yggdrasil.hjson" = {
    restartUnits = [ "yggdrasil.service" ];
  };

  networking.firewall.allowedTCPPorts = [
    secrets.ogma.yggdrasil_listen_port
  ];

}

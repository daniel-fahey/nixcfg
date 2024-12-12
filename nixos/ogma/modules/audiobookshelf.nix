{ secrets, ... }:

{
  services.audiobookshelf = {
    enable = true;
    host = "::1";
  };

  users.groups.media.members = [ "audiobookshelf" ];

  services.nginx = {
    # https://github.com/advplyr/audiobookshelf?tab=readme-ov-file#nginx-reverse-proxy
    virtualHosts."abs.${secrets.ogma.additional_domain}" = {
      forceSSL = true;
      enableACME = true;
      listenAddresses = [
        "${secrets.ogma.additional_ipv4_address}"
      ];
      locations."/" = {
        proxyPass = "http://[::1]:8000";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header Host $host;
          client_max_body_size 10240M;
        '';
      };
    };
    appendHttpConfig = ''
      access_log /var/log/nginx/audiobookshelf.access.log;
      error_log /var/log/nginx/audiobookshelf.error.log;
    '';
  };

}
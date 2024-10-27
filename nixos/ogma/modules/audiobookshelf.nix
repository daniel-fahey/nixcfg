{ secrets, ... }:

{
  services.audiobookshelf = {
    enable = true;
    host = "::1";
  };

  # Add users to their respective groups
  users.groups.audiobookshelf.members = [ "syncthing" ];
  users.groups.media.members = [ "audiobookshelf" ];

  # Add activation script to set initial permissions
  system.activationScripts.audiobooksPermissions = {
    text = ''
      # Set syncthing root dir group to media with read/execute
      chown syncthing:media /var/lib/syncthing
      chmod 750 /var/lib/syncthing

      # Set full permissions for Libation directory
      chown -R syncthing:audiobookshelf /var/lib/syncthing/Libation
      chmod -R 770 /var/lib/syncthing/Libation
    '';
    deps = [ "users" "groups" ];
  };

services.nginx = {
  # https://github.com/advplyr/audiobookshelf?tab=readme-ov-file#nginx-reverse-proxy
  virtualHosts."abs.${secrets.ogma.additional_domain}" = {
    forceSSL = true;
    enableACME = true;
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
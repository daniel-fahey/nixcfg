{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.web-key-directory;
  
in {
  options.services.web-key-directory = {
    enable = mkEnableOption "Web Key Directory";

    domain = mkOption {
      type = types.str;
      description = "Domain name for which WKD is served";
    };

    secretKeys = mkOption {
      type = types.listOf types.path;
      description = "List of paths to sops secrets containing OpenPGP private keys";
      example = ''[ config.sops.secrets."gpg_keys/info".path ]'';
    };

    ipv4 = mkOption {
      type = types.str;
      description = "IPv4 address to bind services to";
      default = "0.0.0.0";
    };

    ipv6 = mkOption {
      type = types.str;
      description = "IPv6 address to bind services to";
      default = "::";
    };


  };

  config = mkIf cfg.enable {
    # Create service user
    users.users.wkd-generator = {
      isSystemUser = true;
      group = config.services.nginx.group; # Make part of the nginx group
      description = "Web Key Directory generator";
    };

    users.groups.wkd-generator = {};

    systemd.services.generate-wkd = {
      description = "Generate Web Key Directory";
      
      path = with pkgs; [ gnupg coreutils ];

      script = ''
        # Create a temporary GNUPG home
        export GNUPGHOME=$(mktemp -d)
        trap 'rm -rf $GNUPGHOME' EXIT
        chmod 700 $GNUPGHOME

        # Create the WKD base directory with correct permissions
        WKD_BASE="/var/lib/web-key-directory/${cfg.domain}"
        
        # Make sure the directory exists with the right permissions
        mkdir -p "$WKD_BASE"
        chmod 750 "$WKD_BASE"
        
        # Create the WKD structure and policy file
        mkdir -p "$WKD_BASE/.well-known/openpgpkey/${cfg.domain}/hu"
        touch "$WKD_BASE/.well-known/openpgpkey/policy"

        # Import all private keys
        ${concatMapStringsSep "\n" (keyPath: ''
          if [ -f "${keyPath}" ]; then
            cat "${keyPath}" | gpg --batch --import
          else
            echo "Warning: Key file ${keyPath} not found"
            exit 1
          fi
        '') cfg.secretKeys}

        # Create WKD entries for all keys with emails in our domain
        # gpg-wks-client expects to be run from the parent of 'openpgpkey'
        cd "$WKD_BASE/.well-known"
        gpg --list-options show-only-fpr-mbox -k "@${cfg.domain}" | \
          gpg-wks-client --install-key

        # Set readable group permissions
        find "$WKD_BASE" -type d -exec chmod 750 {} \;
        find "$WKD_BASE" -type f -exec chmod 640 {} \;
      '';

      serviceConfig = {
        Type = "oneshot";
        User = "wkd-generator";
        Group = config.services.nginx.group;
        StateDirectory = "web-key-directory/${cfg.domain}";
        StateDirectoryMode = "0750";
        UMask = "0027"; # rwxr-x---
        RemainAfterExit = true;
      };

      wantedBy = [ "multi-user.target" ];
      before = [ "nginx.service" ];
    };

    services.nginx.virtualHosts."openpgpkey.${cfg.domain}" = {
      forceSSL = true;
      enableACME = true;
      root = "/var/lib/web-key-directory/${cfg.domain}";

      extraConfig = "autoindex off;";

      locations."/.well-known/openpgpkey/" = {
        extraConfig = ''
          add_header Access-Control-Allow-Origin "*" always;
        '';
      };

      locations."/.well-known/openpgpkey/${cfg.domain}/hu/" = {
        extraConfig = ''
          default_type application/octet-stream;
          add_header Access-Control-Allow-Origin "*" always;
          add_header Content-Disposition attachment;
          try_files $uri =404;
        '';
      };

      listenAddresses = [ cfg.ipv4 "[${cfg.ipv6}]" ];
    };


  };
}
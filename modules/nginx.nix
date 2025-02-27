{ facts, config, ... }:
{
  security.acme = {
    acceptTerms = true;
    defaults.email = facts.acme.email;
    # defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory"; # Staging
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    # Default server to handle ACME challenges and reject unknown hosts
    virtualHosts."_" = {
      default = true;
      listen = [
        { addr = "0.0.0.0"; port = 80; }
        { addr = "[::]"; port = 80; }
        { addr = "0.0.0.0"; port = 443; ssl = true; }
        { addr = "[::]"; port = 443; ssl = true; }
      ];
      
      # Handle ACME challenges
      locations."/.well-known/acme-challenge" = {
        root = "/var/lib/acme/acme-challenge";
      };

      # Reject everything else
      locations."/" = {
        extraConfig = ''
          return 444;
        '';
      };
      
      rejectSSL = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
{ secrets, config, ... }:
{
  security.acme = {
    acceptTerms = true;
    defaults.email = secrets.acme.email;
    # defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory"; # Staging
    certs."${secrets.ogma.domain}" = {
      extraDomainNames = [
        "mx1.${secrets.ogma.domain}"
        "mail.${secrets.ogma.domain}"
        "mta-sts.${secrets.ogma.domain}"
        "autoconfig.${secrets.ogma.domain}"
        "autodiscover.${secrets.ogma.domain}"
        "cloud.${secrets.ogma.domain}"
        "office.${secrets.ogma.domain}"
      ];
      group = config.services.nginx.group;
      reloadServices = [
        "nginx"
        "stalwart-mail"
      ];
      webroot = "/var/lib/acme/acme-challenge";
    };
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    # Default server to handle direct IP access and unknown subdomains
    virtualHosts."_" = {
      default = true;
      # Add specific IP addresses to catch-all server
      listen = [
        # Main IP
        { addr = secrets.ogma.ipv4_address; port = 80; }
        { addr = secrets.ogma.ipv4_address; port = 443; }
        { addr = "[${secrets.ogma.ipv6_address}]"; port = 80; }
        { addr = "[${secrets.ogma.ipv6_address}]"; port = 443; }
        # Secondary IP
        { addr = secrets.ogma.additional_ipv4_address; port = 80; }
        { addr = secrets.ogma.additional_ipv4_address; port = 443; }
      ];
      rejectSSL = true;
      extraConfig = ''
        return 444;
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}

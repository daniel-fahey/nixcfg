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
      reloadServices = [ "nginx" "stalwart-mail" ];
      webroot = "/var/lib/acme/acme-challenge";
    };
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}

{ secrets, config, ... }:
{
  security.acme = {
    acceptTerms = true;
    defaults.email = secrets.acme.email;
    # defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory"; # Staging
    certs."${secrets.ogma.additional_domain}" = {
      extraDomainNames = [ 
        "mx1.${secrets.ogma.additional_domain}"
        "mail.${secrets.ogma.additional_domain}"
        "mta-sts.${secrets.ogma.additional_domain}"
        "autoconfig.${secrets.ogma.additional_domain}"
        "autodiscover.${secrets.ogma.additional_domain}"
        "cloud.${secrets.ogma.additional_domain}"
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

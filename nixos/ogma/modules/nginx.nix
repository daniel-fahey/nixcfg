{
  security.acme = {
    acceptTerms = true;
    defaults.email = "daniel.fahey@pm.me";
    # defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory"; # Staging
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}

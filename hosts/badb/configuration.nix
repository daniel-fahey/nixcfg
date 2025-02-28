{
  modulesPath,
  lib,
  pkgs,
  config,
  facts,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];

  # System Configuration
  system.stateVersion = "24.05";
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";
  environment.variables.EDITOR = "vim";

  # Boot Configuration
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot = {
        enable = true;
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/efi";
      };
    };
  };

  # Nix Configuration
  nix = {
    nixPath = [ "nixpkgs=${pkgs.path}" ]; # for `nix-shell -p ...`
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [ "https://nix-community.cachix.org" ];
      trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
    };
  };

  # Security and SSH Configuration
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      X11Forwarding = true;
    };
  };

  # Networking

  networking = {
    hostName = "badb";
    nameservers = [ "1.1.1.1" "8.8.8.8" ];  # Cloudflare and Google DNS servers, TODO https://www.privacyguides.org/en/dns/
    interfaces.enp1s0 = {
      ipv6.addresses = [
        {
          address = "${facts.badb.ipv6_address}1";
          prefixLength = 128;
        }
      ];
    };
    defaultGateway6 = {
      address = "fe80::1";
      interface = "enp1s0";
    };
  };

  services.stalwart = {
    enable = true;
    domain = facts.badb.domain;
  };

  services.web-key-directory = {
    enable = true;
    domain = facts.badb.domain;
    secretKeys = [ config.sops.secrets."gpg_keys/info.asc".path ];
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = facts.acme.email;
  };

  services.nginx.commonHttpConfig = ''
    access_log syslog:server=unix:/dev/log,tag=nginx combined;
    error_log syslog:server=unix:/dev/log info;
  '';

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # User Configuration
  users = {
    mutableUsers = false;
    users = {
      daniel = {
        isNormalUser = true;
        extraGroups = [
          "wheel" # Enable 'sudo' for the user.
          "media"
        ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJbyBsOYlK6k6hQvpOwe9v6xC0mqpUvaR7oRUjsKU7EZ daniel@laptop"
        ];
        hashedPasswordFile = config.sops.secrets.daniel_hpw.path;
      };
      root.openssh.authorizedKeys.keys = config.users.users.daniel.openssh.authorizedKeys.keys;
    };
  };

  # Secrets Management
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  sops.secrets = {
    daniel_hpw.neededForUsers = true;
    "gpg_keys/info.asc" = {
      owner = "wkd-generator";
      group = "wkd-generator";
    };
    "authentik/.env" = {};
  };

  # System Packages
  environment.systemPackages = with pkgs; [
    # System utilities
    rsync
    curl
    git
    vim
    tmux
    bash-completion
    pciutils
    ethtool

    # Monitoring and debugging
    htop
    iotop
    iftop
    lsof
    strace

    # Disk usage
    ncdu
    btdu

    # Network tools
    nettools
    nmap
    tcpdump
    dig
    yggdrasil
    speedtest-go

    # Development
    go

    # Terminal
    kitty
    unibilium
  ];

  services.authentik = {
    enable = true;
    environmentFile = config.sops.secrets."authentik/.env".path;
    
    settings = {
      disable_startup_analytics = true;
      avatars = "initials";
      email = {
        host = "mail.${facts.badb.domain}";
        port = 587;
        username = "authentik@${facts.badb.domain}";
        use_tls = true;
        from = "authentik@${facts.badb.domain}";
      };
    };
    
    nginx = {
      enable = true;
      enableACME = true;
      host = "auth.${facts.badb.domain}";
    };
  };
}

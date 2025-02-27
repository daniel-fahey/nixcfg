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
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
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
    ipv4 = facts.badb.ipv4_address;
    ipv6 = "${facts.badb.ipv6_address}1";
  };

  sops.secrets = {
    "gpg_keys/info.asc" = {
      owner = "wkd-generator";
      group = "wkd-generator";
    };
    daniel_hpw.neededForUsers = true;
  };

  services.web-key-directory = {
    enable = true;
    domain = facts.badb.domain;
    secretKeys = [ config.sops.secrets."gpg_keys/info.asc".path ];
    ipv4 = facts.badb.ipv4_address;
    ipv6 = "${facts.badb.ipv6_address}1";
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
}

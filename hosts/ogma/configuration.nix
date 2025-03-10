{
  config,
  pkgs,
  facts,
  ...
}:

{
  # This will add secrets.yaml to the nix store
  sops.defaultSopsFile = ./secrets.yaml;

  # This will automatically import SSH keys as age keys
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  sops.secrets.daniel_hpw.neededForUsers = true;

  users.users = {
    root.openssh.authorizedKeys.keys = config.users.users.daniel.openssh.authorizedKeys.keys;
    daniel = {
      isNormalUser = true;
      extraGroups = [
        "wheel" # Enable ‘sudo’ for the user.
        "media"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJbyBsOYlK6k6hQvpOwe9v6xC0mqpUvaR7oRUjsKU7EZ daniel@laptop"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGugUzZfl281ISKRvmlIPP9DCXXaYtat4pjG7OtFv+Sg root@laptop"
      ];
      hashedPasswordFile = config.sops.secrets.daniel_hpw.path;
    };
  };

  # This line will populate NIX_PATH
  nix.nixPath = [ "nixpkgs=${pkgs.path}" ]; # for `nix-shell -p ...`

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.trusted-substituters = [ "https://cache.nixos.org/" ];
  nix.settings.trusted-users = [
    "root"
    "daniel"
  ];
  nix.settings.substituters = [ "https://cuda-maintainers.cachix.org" ];
  nix.settings.trusted-public-keys = [ "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E=" ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "1";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/efi";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      X11Forwarding = true;
    };
  };

  services.fail2ban.enable = true;

  environment.variables.EDITOR = "vim";

  networking = {
    hostName = "ogma";
    nameservers = [ "1.1.1.1" "8.8.8.8" ];  # Cloudflare and Google DNS servers, TODO https://www.privacyguides.org/en/dns/
    interfaces = {
      eno1 = {
        ipv4.addresses = [
          {
            address = facts.ogma.ipv4_address;
            prefixLength = 24;
          }
          {
            address = facts.ogma.additional_ipv4_address;
            prefixLength = 24;
          }
        ];
        ipv6.addresses = [
          {
            address = facts.ogma.ipv6_address;
            prefixLength = 64;
          }
          {
            address = "${facts.ogma.ipv6_address}1";
            prefixLength = 128;
          }
        ];
      };
      eno2.useDHCP = false;
    };
    defaultGateway = {
      address = facts.ogma.ipv4_gateway;
      interface = "eno1";
    };
    defaultGateway6 = {
      address = facts.ogma.ipv6_gateway;
      interface = "eno1";
    };
  };

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

  # Ensure the rsync package is available on the system
  environment.systemPackages = with pkgs; [
    rsync
    curl
    git
    htop
    vim
    tmux
    lsof
    nettools
    nmap
    strace
    tcpdump
    iotop
    ncdu
    btdu
    iftop
    bash-completion
    pciutils
    ethtool
    go
    yggdrasil
    speedtest-go
    unibilium
    kitty
    git-crypt
    dig
    libation
    lynis
  ];

  services.btrfs.autoScrub = {
    enable = true;
    interval = "daily";
  };

  # Define the activation script
  system.activationScripts.copyESP = {
    text = ''
      # Ensure the mount point for the secondary ESP exists
      mkdir -p /efi2

      # Mount the backup ESP
      mount /dev/disk/by-partlabel/disk-backup-ESP /efi2

      # Use rsync to copy the ESP contents. This will only copy changes.
      ${pkgs.rsync}/bin/rsync --archive --delete /efi/ /efi2/

      # Unmount the secondary ESP
      umount /efi2
    '';
    deps = [ ];
  };

  # ssh setup
  boot.initrd.network.enable = true;
  boot.initrd.network.ssh = {
    enable = true;
    port = 2222;
    shell = "/bin/cryptsetup-askpass";
    authorizedKeys = config.users.users.daniel.openssh.authorizedKeys.keys;
    hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
  };

  boot.initrd.availableKernelModules = [ "igb" ];

  boot.kernelParams = [
    "ip=dhcp"
    "console=ttyS0,115200n8"
  ];

  zramSwap = {
    enable = true;
    swapDevices = 1; # One zram device
    memoryPercent = 95; # Use up to 95% of total RAM
    algorithm = "zstd"; # Use Zstandard compression
    priority = 10; # Higher priority than disk-based swap
    # Optional: memoryMax, writebackDevice
  };

  system.stateVersion = "23.11";
}

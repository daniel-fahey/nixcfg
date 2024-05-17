{ lib, ... }:

{

  disko.devices.disk.backup = {
    type = "disk";
    device = "/dev/sdb";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "550M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountOptions = [ "umask=0077" ];
            mountpoint = null; # Not mounting this one since we already have the primary drive's ESP mounted
          };
        };
        LUKS = {
          size = "100%";
          content = {
            type = "luks";
            name = "backup-crypt";
            passwordFile = "/tmp/disk.key";
            content = null; # Not specifying content since the RAID1 will be created from the primary drive
          };
        };
      };
    };
  };

  disko.devices.disk.primary = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "550M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountOptions = [ "umask=0077" ]; # https://github.com/nix-community/disko/issues/527#issuecomment-1924076948
            mountpoint = "/efi";
          };
        };
        LUKS = {
          size = "100%";
          content = {
            type = "luks";
            name = "primary-crypt";
            passwordFile = "/tmp/disk.key"; # Interactive
            content = {
              type = "btrfs";
              extraArgs = [ "--force" "--metadata raid1" "--data raid1" "/dev/mapper/backup-crypt" ];
              subvolumes = {
                "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd:1" "noatime" ];
                  };
                "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd:1" "noatime" ];
                  };
                "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd:1" "noatime" ];
                  };
                "@persist" = {
                    mountpoint = "/persist";
                    mountOptions = [ "compress=zstd:1" "noatime" ];
                  };
                "@log" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "compress=zstd:1" "noatime" ];
                  };
              };
            };
          };
        };
      };
    };
  };

}

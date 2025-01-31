{ lib, ... }:
let
  defaultMountOptions = [ "compress=zstd" "noatime" ];
in
{
  disko.devices.disk.primary = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          priority = 1;
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/efi";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          priority = 2;
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "@" = {
                mountpoint = "/";
                mountOptions = defaultMountOptions;
              };
              "@home" = {
                mountpoint = "/home";
                mountOptions = defaultMountOptions;
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = defaultMountOptions;
              };
              "@persist" = {
                mountpoint = "/persist";
                mountOptions = defaultMountOptions;
              };
              "@log" = {
                mountpoint = "/var/log";
                mountOptions = defaultMountOptions;
              };
            };
          };
        };
      };
    };
  };
}
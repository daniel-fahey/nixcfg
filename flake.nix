{
  description = "My Nix configs (NixOS, home-manager & flake templates)";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    age-key = {
      url = "file+file:///dev/null";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      sops-nix,
      age-key,
      ...
    }:
    let
      secrets = builtins.fromJSON (
        builtins.readFile (
          nixpkgs.legacyPackages.x86_64-linux.runCommand "decrypt-privates"
            {
              nativeBuildInputs = [ nixpkgs.legacyPackages.x86_64-linux.sops ];
            }
            ''
              export SOPS_AGE_KEY="$(cat ${age-key.outPath})"
              sops -d ${self}/privates.json > $out
            ''
        )
      );
    in
    {
      nixosConfigurations = {
        ogma = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit secrets; };
          modules = [
            ./hosts/ogma/configuration.nix
            ./hosts/ogma/hardware-configuration.nix
            ./hosts/ogma/disk-config.nix
            ./modules/borg.nix
            ./modules/nginx.nix
            ./modules/vaultwarden.nix
            ./modules/xandikos.nix
            ./modules/yggdrasil.nix
            ./modules/photoprism.nix
            ./modules/syncthing.nix
            ./modules/nextcloud.nix
            ./modules/collabora-online.nix
            ./modules/audiobookshelf.nix
            ./modules/refused-connections.nix
            ./modules/stalwart.nix
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
          ];
        };
        badb = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./hosts/badb/configuration.nix
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
          ];
        };
      };
    };
}

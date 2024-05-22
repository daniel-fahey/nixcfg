{
  description = "My Nix configs (NixOS, home-manager & flake templates)";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, sops-nix, ... }:
  let
    secrets = builtins.fromJSON (builtins.readFile "${self}/secrets.json");
  in
  {
    nixosConfigurations.ogma = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit secrets; };
      modules = [
        ./nixos/ogma/configuration.nix
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
      ];
    };
  };
}

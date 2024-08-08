{
  description = "A devShell for Talos on Hetzner Cloud using Terraform and SOPS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      forAllSystems =
        function:
        nixpkgs.lib.genAttrs
          [
            "x86_64-linux"
            "aarch64-linux"
            "x86_64-darwin"
            "aarch64-darwin"
          ]
          (
            system:
            function (
              import nixpkgs {
                inherit system;
                config.allowUnfree = true;
              }
            )
          );
    in
    {
      formatter = forAllSystems (pkgs: pkgs.nixfmt);

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            terraform
            terraform-ls
            hcloud
            packer
            talosctl
            kubectl
            kubernetes-helm
            sops
            yq-go
          ];

          shellHook = ''
            export TALOSCONFIG="$PWD/.talos/config"
            export KUBECONFIG="$PWD/.kube/config"
            export HCLOUD_TOKEN=$(${pkgs.sops}/bin/sops -d secrets.yaml | ${pkgs.yq-go}/bin/yq -r .hcloud_token)
            export TF_VAR_hcloud_token=$HCLOUD_TOKEN
          '';
        };
      });
    };
}

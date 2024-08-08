{
  description = "A basic flake for minikube";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      forAllSystems =
        function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ] (system: function (import nixpkgs { inherit system; }));
    in
    {
      formatter = forAllSystems (pkgs: pkgs.nixfmt);

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            kubectl
            kubernetes-helm
            minikube
            docker-machine-kvm2
          ];

          shellHook = ''
            export MINIKUBE_HOME="$PWD/.minikube"
            export KUBECONFIG="$PWD/.kube/config"
          '';
        };
      });
    };
}

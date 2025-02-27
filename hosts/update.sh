#! /usr/bin/env nix-shell
#! nix-shell -i bash -p sops yq-go
set -euo pipefail

ip=$(sops -d "$1/secrets.yaml" | yq -r .ipv4)

nixos-rebuild switch \
--flake ".#$1" \
--target-host "root@$ip" \
--build-host "root@$ip" \
--show-trace \
-v \
--override-input age-key file+file://<(printf %s "$SOPS_AGE_KEY")
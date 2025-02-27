#! /usr/bin/env nix-shell
#! nix-shell -i bash -p sops yq-go
set -euo pipefail

[ $# -eq 1 ] || { echo "Usage: $0 DIRECTORY" >&2; exit 1; }

ip=$(sops -d "$1/secrets.yaml" | yq -r .ipv4)
# key=$(sops -d "$1/secrets.yaml" | yq -r .cryptroot)
# --disk-encryption-keys /tmp/disk.key <(echo "$key") \

nix run github:nix-community/nixos-anywhere -- \
--extra-files "$1/extra-files" \
--build-on-remote \
--flake ".#$1" "root@$ip"
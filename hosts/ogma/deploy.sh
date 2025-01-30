#!/usr/bin/env bash

# May need to install rsync if using standard NixOS ISO
# ssh root@$(sops -d secrets.yaml | yq -r .ipv4) "nix-env -iA nixos.rsync"

# Install NixOS to the host system with our secrets
nix run github:nix-community/nixos-anywhere -- \
--extra-files extra-files \
--disk-encryption-keys /tmp/disk.key <(sops -d secrets.yaml | yq -r .cryptroot) \
--build-on-remote \
--flake .#ogma root@$(sops -d secrets.yaml | yq -r .ipv4)
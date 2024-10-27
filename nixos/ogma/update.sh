#!/usr/bin/env bash

# remote update
nixos-rebuild switch \
--flake .#ogma \
--target-host root@$(sops -d secrets.yaml | yq -r .ipv4) \
--build-host root@$(sops -d secrets.yaml | yq -r .ipv4) \
--show-trace \
-v \
--override-input age-key file+file://<(printf %s "$SOPS_AGE_KEY")

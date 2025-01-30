#!/usr/bin/env bash

initrd_secrets=extra-files/etc/secrets/initrd
host_keys=extra-files/etc/ssh

# create directory for initrd secrets
install -d -m755 $initrd_secrets

# create directory for host keys
install -d -m755 $host_keys

# generate initrd keys
ssh-keygen -t ed25519 -N "" -f $initrd_secrets/ssh_host_ed25519_key -C "initrd"

# generate host keys
ssh-keygen -t ed25519 -N "" -f $host_keys/ssh_host_ed25519_key -C "host"

# get age public key
nix-shell -p ssh-to-age --run 'cat etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'
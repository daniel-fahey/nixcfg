#! /usr/bin/env nix-shell
#! nix-shell -i bash -p openssh coreutils ssh-to-age
set -euo pipefail

[ $# -eq 1 ] || { echo "Usage: $0 DIRECTORY" >&2; exit 1; }

dir="$1/extra-files"
initrd="$dir/etc/secrets/initrd"
host="$dir/etc/ssh"

install -d -m700 "$initrd" "$host"

[ ! -f "$initrd/ssh_host_ed25519_key" ] && 
    ssh-keygen -t ed25519 -N "" -f "$initrd/ssh_host_ed25519_key" -C "initrd"

[ ! -f "$host/ssh_host_ed25519_key" ] && 
    ssh-keygen -t ed25519 -N "" -f "$host/ssh_host_ed25519_key" -C "host"

ssh-to-age < "$host/ssh_host_ed25519_key.pub"
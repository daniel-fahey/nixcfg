#! /usr/bin/env nix-shell
#! nix-shell -i bash -p openssl libargon2 coreutils

# Determine the number of processors to use (total available minus one)
processors=$(( $(nproc) - 1 ))
# Ensure we have at least 1 processor
processors=$(( processors > 0 ? processors : 1 ))

# Generate a random 16-byte salt
salt=$(openssl rand -hex 16)

# Prompt for the password (without echoing to the terminal)
read -s -p "Enter password: " password
echo

# Hash the password using Argon2 with dynamic parallelism
hashed_password=$(echo -n "$password" | argon2 "$salt" -e -id -t 3 -m 12 -p $processors -l 32)

echo "Hashed password: $hashed_password"
echo "Parallelism used: $processors"

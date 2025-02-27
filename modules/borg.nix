{ config, facts, ... }:
{
  
  sops.secrets."borg/id_ed25519" = {};
  sops.secrets."borg/passphrase" = {};

  services.openssh.knownHosts."borgbase" = {
    hostNames = [ "${facts.ogma.borgbase}.repo.borgbase.com" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMS3185JdDy7ffnr0nLWqVy8FaAQeVh1QYUSiNpW5ESq";
  };
    
  services.borgbackup.jobs.office = {
    paths = [
      "/var/backup/vaultwarden"
      "/var/lib/xandikos/user"
      "/persist"
    ];
    repo = "ssh://${facts.ogma.borgbase}@${facts.ogma.borgbase}.repo.borgbase.com/./repo";
    environment = {
        BORG_RSH = "ssh -i ${config.sops.secrets."borg/id_ed25519".path}";
    };
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat ${config.sops.secrets."borg/passphrase".path}";
    };
    compression = "zstd,1";
    startAt = "daily";
  };
}

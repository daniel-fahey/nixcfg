{ facts, ... }:

{
  services.syncthing = {
    enable = true;
    guiAddress = "[${facts.ogma.yggdrasil_ipv6}]:8384";
    settings = {
      gui = {
        user = "admin";
        password = facts.ogma.syncthing_gui_password;
      };
      options = {
        globalAnnounceEnabled = true;
        relaysEnabled = true;
        localAnnounceEnabled = false;
        urAccepted = -1; # Disable usage reporting
      };
      devices = {
        helios64.id = facts.syncthing.devices.helios64;
        nothing1.id = facts.syncthing.devices.nothing1;
        laptop.id = facts.syncthing.devices.laptop;
      };
      folders = {
        PhoneCamera2 = {
          enable = true;
          id = facts.syncthing.folders.PhoneCamera2;
          path = "/persist/media/photoprism/originals/PhoneCamera2";
          devices = [
            "nothing1"
            "helios64"
          ];
          rescanIntervalS = 3600;
          type = "receiveonly";
        };
        AIFF = {
          enable = true;
          id = facts.syncthing.folders.AIFF;
          path = "~/AIFF";
          devices = [
            "helios64"
          ];
          rescanIntervalS = 3600;
          type = "receiveonly";
        };
      };
    };
  };

  networking.firewall = {
    # Allow Syncthing traffic on all interfaces
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [ 22000 21027 ];

    # Allow Syncthing GUI access only on the Yggdrasil interface (assumed to be tun0)
    interfaces.tun0 = {
      allowedTCPPorts = [ 8384 ];
    };
  };

}

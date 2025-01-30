{
  services.fail2ban = {
    ignoreIP = [
      # if needed
    ];
    jails = {
      refused-connections = {
        settings = {
          enabled = true;
          port = "all";
          filter = "refused-connections";
          maxretry = 5;
          findtime = "1h";
          bantime = "6h";
          backend = "systemd";
          journalmatch = "SYSLOG_FACILITY=0";
          action = "iptables-allports";
        };
      };
    };
  };

  environment.etc."fail2ban/filter.d/refused-connections.conf".text = ''
    [Definition]
    failregex = refused connection: IN=.* SRC=<HOST> DST=.* PROTO=TCP .*
  '';
}
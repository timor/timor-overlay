{ config, lib, pkgs, ...}:

let
  inherit (lib) mkOption mkEnableOption mkIf;
  cfg = config.services.spacenavd;
in

{
  options = {
    services.spacenavd = {
      enable = mkEnableOption "Enable Spacenavd User Service";

      uid = mkOption {
        # type = lib.types.nullOr lib.types.int;
        type = lib.types.int;
        description = ''
          For which user to start the service.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    services.udev.extraRules = ''
      KERNEL=="event[0-9]*", SUBSYSTEM=="input", SUBSYSTEMS=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c626", TAG+="uaccess"
    '';
    systemd.user.services.spacenavd = {
      # environment = {
      #   LD_PRELOAD = "${pkgs.libredirect}/lib/libredirect.so";
      #   NIX_REDIRECTS = "/var/run=/run/spacenavd";
      # };
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "forking";
        ExecStart = "${lib.getBin pkgs.spacenavd}/bin/spacenavd -l syslog -c %E/spnavrc -p %t/spnavd.pid -v";
        StandardError = "syslog";
        PIDFile = "%t/spnavd.pid";
      };
      unitConfig = {
        ConditionUser = cfg.uid;
        ConditionEnvironment = "DISPLAY";
      };
    };
  };
}

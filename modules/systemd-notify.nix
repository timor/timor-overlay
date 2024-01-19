{config, lib, pkgs, ...}:

with lib;

let cfg = config.services.systemd-notify;

in

{
  options = {
    services.systemd-notify =
      {
        enable = mkEnableOption "Helper Service to send notifications for systemd service stuff.";

        timeout = mkOption {
          type = types.str;
          default = "0";
          description = "Display duration (in seconds) of notifications. Use 0 for indefinite.";
        };
      };

  };

  config = mkIf cfg.enable {

    systemd.services."notify-service-fail@" = {

      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.notify-send-all}/bin/notify-send-all -t ${cfg.timeout} -i error 'Service %i failed.'";
      };
    };
  };
}

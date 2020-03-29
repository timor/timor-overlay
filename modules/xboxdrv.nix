{ pkgs, config, lib, ...}:

let
  inherit (lib) mkIf mkEnableOption mkOption getBin;
  cfg = config.services.xboxdrv;
  configFile = pkgs.writeText "xboxdrv.conf" cfg.conf;

in

{
  options = {
    services.xboxdrv = {
      enable = mkEnableOption "Enable xboxdrv system service";

      conf = mkOption {
        description = "Configuration lines for xboxdrv.conf";
        type = lib.types.lines;
        default = ''
          [xboxdrv]
          mimic-xpad=true
          '';
        example = ''
          [xboxdrv]
          deadzone = 4000
          mimic-xpad-wireless = true
          device-name = "XBOX 360 Wireless Receiver";
          next-controller = true
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    boot.blacklistedKernelModules = [ "xpad" ];
    boot.kernelModules = [ "uinput" "joydev" ];
    systemd.services.xboxdrv = {
      description = "Xboxdrv User-space Gamepad Controller Daemon";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "forking";
        PIDFile = "/run/xboxdrv.pid";
      };
      script = ''
        ${getBin pkgs.xboxdrv}/bin/xboxdrv \
          --daemon --detach --pid-file /run/xboxdrv.pid \
          --dbus disabled --silent \
          --ui-clear --config ${configFile}
      '';
    };
  };
}

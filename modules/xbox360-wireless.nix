{ pkgs, config, lib, ...}:

let
  inherit (lib) mkIf mkEnableOption mkOption getBin;
  cfg = config.hardware.xbox360Wireless;
  configFile = pkgs.writeText "xboxdrv.conf" cfg.conf;

in

{
  options = {
    hardware.xbox360Wireless = {
      enable = mkEnableOption "Configure xboxdrv for XBox360 Wireless Controllers";

      conf = mkOption {
        description = "Configuration lines for xboxdrv.conf";
        type = lib.types.lines;
        default = ''
          [xboxdrv]
          # [controller0]
          wireless-id = 0
          led = 6
          mimic-xpad = true
          device-name="Xbox 360 Wireless Receiver"
          next-controller = true

          # [controller1]
          wireless-id = 1
          led = 7
          mimic-xpad = true
          device-name="Xbox 360 Wireless Receiver"
          next-controller = true

          # [controller2]
          wireless-id = 2
          led = 8
          mimic-xpad = true
          device-name="Xbox 360 Wireless Receiver"
          next-controller = true

          # [controller4]
          wireless-id = 3
          led = 9
          mimic-xpad = true
          device-name="Xbox 360 Wireless Receiver"
          '';
      };
    };
  };

  config = lib.mkIf cfg.enable {

    boot.blacklistedKernelModules = [ "xpad" ];
    boot.kernelModules = [ "uinput" "joydev" ];

    systemd.services.xboxdrv = {
      description = "XBox360 Wireless Gamepad Controller Daemon";
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

    services.udev.extraRules = ''
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="0719", TAG+="uaccess", MODE="0660"
    '';
  };
}

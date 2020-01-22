{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.xserver.windowManager.spacemacsOS;
in
{
  options = {
    services.xserver.windowManager.spacemacsOS = {
      enable = mkEnableOption "spacemacsOS";
      startExpression = mkOption {
        default = "(exwm-enable)";
        type = types.str;
        description = ''
          Expression that is used to start exwm.  Can be overridden
          with code that is defined in the spacemacs configuration.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    services.xserver.windowManager.session = singleton {
      name = "SpacemacsOS";
      start = ''
        export _JAVA_AWT_WM_NONREPARENTING=1
        systemctl --user start exwm.target
        ${pkgs.spacemacs}/bin/spacemacs --eval "${cfg.startExpression}"
        systemctl --user stop exwm.target
      '';
    };

    programs.xss-lock.enable = true;

    systemd.user.services.xss-lock.wantedBy = lib.mkForce [ "exwm.target" ];
    systemd.user.services.xss-lock.partOf = lib.mkForce [ "exwm.target" ];

    systemd.user.targets.exwm = {
      enable = true;
      description = ''
        Session Target which is started when EXWM is started
        '';
    };

    fonts.fonts = [
      pkgs.source-code-pro
    ];
    environment.systemPackages = [
      pkgs.ripgrep
      pkgs.silver-searcher
      pkgs.git
    ];
  };
}

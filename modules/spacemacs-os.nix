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
        ${pkgs.spacemacs}/bin/spacemacs --eval "${cfg.startExpression}"
      '';
    };
    fonts.fonts = [
      pkgs.source-code-pro
    ];
    environment.systemPackages = [
      pkgs.ag
      pkgs.git
    ];
  };
}

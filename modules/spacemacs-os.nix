{ config, lib, pkgs, ... }:

with lib;

# NOTE: expects exwm-enabled spacemacs in the user's path!

let
  cfg = config.services.xserver.windowManager.spacemacsOS;

  desktopApplicationFile = pkgs.writeTextFile {
    name = "emacsclient.desktop";
    destination = "/share/applications/emacsclient.desktop";
    text = ''
      [Desktop Entry]
      Name=Emacsclient(SpacemacsOS)
      GenericName=Text Editor
      Comment=Open in Spacemacs(server needed)
      MimeType=text/english;text/plain;inode/directory;
      Exec=emacsclient -n %F
      Icon=spacemacs
      Type=Application
      Terminal=false
      Categories=Development;TextEditor;
      StartupWMClass=SpacemacsClient
      Keywords=Text;Editor;
    '';
  };
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
        spacemacs -fs --eval "${cfg.startExpression}"
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
      desktopApplicationFile
    ];
  };
}

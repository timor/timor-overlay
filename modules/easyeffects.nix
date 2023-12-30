# Source: https://github.com/nix-community/home-manager/blob/master/modules/services/easyeffects.nix
{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.easyeffects;

  presetOpts = optionalString (cfg.preset != "") "--load-preset ${cfg.preset}";

in {
  # meta.maintainers = [ maintainers.fufexan ];

  options.services.easyeffects = {
    enable = mkEnableOption ''
      Easyeffects daemon.
      Note, it is necessary to add
      <programlisting language="nix">
      programs.dconf.enable = true;
      </programlisting>
      to your system configuration for the daemon to work correctly'';

    preset = mkOption {
      type = types.str;
      default = "";
      description = ''
        Which preset to use when starting easyeffects.
        Will likely need to launch easyeffects to initially create preset.
      '';
    };
  };

  config = mkIf cfg.enable {
    # assertions = [
    #   (hm.assertions.assertPlatform "services.easyeffects" pkgs platforms.linux)
    # ];

    # running easyeffects will just attach itself to gapplication service
    # at-spi2-core is to minimize journalctl noise of:
    # "AT-SPI: Error retrieving accessibility bus address: org.freedesktop.DBus.Error.ServiceUnknown: The name org.a11y.Bus was not provided by any .service files"
    # home.packages = with pkgs; [ easyeffects at-spi2-core ];

    systemd.user.services.easyeffects = {
      # Unit = {
        description = "Easyeffects daemon";
        requires = [ "dbus.service" ];
        after = [ "graphical-session-pre.target" ];
        partOf = [ "graphical-session.target" "pipewire.service" ];
      # };

      wantedBy = [ "graphical-session.target" ];

      serviceConfig = {
        ExecStart =
          "${pkgs.easyeffects}/bin/easyeffects --gapplication-service ${presetOpts}";
        ExecStop = "${pkgs.easyeffects}/bin/easyeffects --quit";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}

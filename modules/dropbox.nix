{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.dropbox;
in
{
  options = {
    services.dropbox = {
      enable = mkEnableOption "dropbox";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services = {
      dropbox = {
        enable = true;
        script = "${pkgs.dropbox}/bin/dropbox";
        wantedBy = [ "default.target" ];
        serviceConfig = {
          RestartSec = 5;
          Restart = "on-failure";
        };
      };
    };
  };
}

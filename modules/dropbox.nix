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
    environment.systemPackages = [
      pkgs.dropbox-cli
    ];

    systemd.user.services = {
      dropbox = {
        enable = cfg.enable;
        script = "${pkgs.dropbox}/bin/dropbox";
        after = [ "local-fs.target" "network.target"];
        wantedBy = [ "default.target" ];
        serviceConfig = {
          RestartSec = 5;
          Restart = "on-failure";
          TimeoutStartSec = "5min";
        };
      };
    };
  };
}

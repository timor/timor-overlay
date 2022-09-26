{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.zwaveJS;
  zwave-server = pkgs.node-zwave-js;
  configFormat = pkgs.formats.json {};
  configFile = pkgs.writeText "zwave-config.js" ''
  module.exports = {
  storage: { cacheDir: "/run/zwave-js"},
  securityKeys: {
      S0_Legacy: Buffer.from("0102030405060708090a0b0c0d0e0f10", "hex")
  }
};
  '';

in

{

  ###### interface

   options = {

    services.zwaveJS = {

      enable = mkEnableOption "Whether to enable Zwave-JS Server";

      device = mkOption {
       type = types.str;
       description = "Z-Wave Adapter dev path";
      };

      configJSON = mkOption {
       type = configFormat.type ;
       default = {
         storage = { cacheDir = "/run/zwave-js"; };
         logConfig = { forceConsole = "true"; };
         securityKeys.S0_Legacy = "";
       };
      };
    };
  };


  ###### implementation

  config = mkIf cfg.enable {

    environment.etc."zwave-js-config.json".source = configFormat.generate "zwave-js-config-config.json" cfg.configJSON;

    systemd.services.zwaveJS = {
      
      after = [ "network.target" ];
      description = "Zwave-JS Server";
      wantedBy = [ "default.target" ];
#       preStart = ''
#         mkdir -p ${cfg.dataDir};
# 	mkdir -p ${playlist_dir};
# 	mkdir -p ${cfg.musicDirectory};
#       '';
#      script = "${zwave-server}/bin/zwave-server --config /etc/zwave-js-config.json ${cfg.device}";
      script = "${zwave-server}/bin/zwave-server --config ${configFile} ${cfg.device}";
#      script = "${zwave-server}/bin/zwave-server ${cfg.device}";
    };

  };
}

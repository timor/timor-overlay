{ config, lib, pkgs, ...}:


let
  cfg = config.services.opensnitch;
  inherit (pkgs) opensnitch writeText iptables;
  inherit (lib) nameValuePair;
  inherit (builtins) listToAttrs;
  makeAlwaysRuleFile = rulePath: name: operator:
    nameValuePair (rulePath + "/${name}.json") {
      source = writeText name (builtins.toJSON {
      inherit name;
      enabled = true;
      action = "allow";
      duration = "always";
      inherit operator;
      });
    };

  makePackageRuleFile = rulePath: pkg: let
    name = "nixos-allow-${lib.strings.getName pkg}";
    in makeAlwaysRuleFile rulePath name {
          type = "regexp";
          operand = "process.path";
          data = "${pkg}/*";
    };

in

{

  options = {
    services.opensnitch = with lib; {
      enable = mkEnableOption "opensnitch";

      uiConfig = mkOption {
        type = types.attrs;
        description = "JSON attribute set for opensnitch ui config";
        default = {
          default_timeout = 60;
          default_action = "deny";
          default_duration = "once";
        };
      };

      startUserService = mkOption {
        type = types.bool;
        description = ''
          If enabled, run the opensnitch-ui process as a user
          service in the graphical session.  If this is disabled,
          opensnitch-ui must be run by other means.  This means that all users share the same rules
        '';
        default = true;
      };
      whitelistPackages = mkOption {
        type = types.listOf types.package;
        description = ''
          List of packages for which to generate rules to allow connections from all processes that are located below
          a package's store path.  Intended for process rules which should survive NixOS updates.
        '';
        default = with pkgs; [ nix ];
      };

    };
  };

  config =
    let
      uiConfig = writeText "ui-config.json" (builtins.toJSON cfg.uiConfig);
    in
    lib.mkIf cfg.enable {

      environment.etc = listToAttrs (map (makePackageRuleFile "opensnitchd/rules") cfg.whitelistPackages);

      environment.systemPackages = if cfg.startUserService then [] else [
        opensnitch.ui
      ];

      systemd.services.opensnitchd = {
        after = [ "network.target" ];
        wants = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        preStart = ''
          mkdir -p /etc/opensnitchd/rules
          chown root:root /etc/opensnitchd
          chmod 700 /etc/opensnitchd
          # mkdir -p /run/opensnitch
        '';
        path = [ iptables ];
        # For some reason there is a problem with not using /tmp for socket file...
        # script = "${lib.getBin opensnitch.daemon}/bin/opensnitchd -log-file /var/log/opensnitchd.log -rules-path /etc/opensnitchd/rules -ui-socket unix:///run/opensnitch/osui.sock -debug";
        script = "${lib.getBin opensnitch.daemon}/bin/opensnitchd -log-file /var/log/opensnitchd.log -rules-path /etc/opensnitchd/rules -ui-socket unix:///tmp/osui.sock";
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = "30";
        };
      };


      systemd.user.services.opensnitch-ui = {
        description = "opensnitch firewall UI process";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        script = "${lib.getBin opensnitch.ui}/bin/opensnitch-ui --config ${uiConfig} --socket unix:///tmp/osui.sock";
        unitConfig.ConditionUser = "!@system";
        enable = cfg.startUserService;
      };
    };
}

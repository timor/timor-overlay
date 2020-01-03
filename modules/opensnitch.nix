{ config, lib, pkgs, ...}:


let
  cfg = config.services.opensnitch;
  inherit (pkgs) opensnitch writeText iptables;
  inherit (lib) nameValuePair mapAttrsToList;
  inherit (builtins) listToAttrs replaceStrings concatMap;
  escapeRuleName = name:
    replaceStrings [ "*" "." "/" ] [ "all" "-" "-" ] name;
  makeAlwaysRuleFile = rulePath: name': operator: let name = escapeRuleName name'; in
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
    name = "nixos-allow-pkg-${lib.strings.getName pkg}";
    in makeAlwaysRuleFile rulePath name {
          type = "regexp";
          operand = "process.path";
          data = "${pkg}/*";
    };
  makeHostRuleFile = rulePath: type: value: let
    name = "nixos-allow-${type}-${value}";
    in makeAlwaysRuleFile rulePath name {
      type = "regexp";
      operand = "dest.${type}";
      data = replaceStrings [ "." "*" ] [ "\\." ".*" ] value;
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

      whitelistHosts = mkOption {
        type = types.listOf types.attrs;
        description = ''
          List of destination hosts for which to create default (regexp) allow rules, regardless of other connection properties.
        '';
        default = [];
        example = ''[ { host = "*.nixos.org" } { ip = "127.0.0.1" } ]'';
      };
    };
  };

  config =
    let
      uiConfig = writeText "ui-config.json" (builtins.toJSON cfg.uiConfig);
    in
    lib.mkIf cfg.enable {

      environment.etc = listToAttrs (
        (map (makePackageRuleFile "opensnitchd/rules") cfg.whitelistPackages)
        ++ concatMap (x: mapAttrsToList (n: v: makeHostRuleFile "opensnitchd/rules" n v) x) cfg.whitelistHosts
      );

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

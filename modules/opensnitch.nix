{ config, lib, pkgs, ...}:


let
  cfg = config.services.opensnitch;
  inherit (pkgs) opensnitchd opensnitch-ui writeText iptables;
  inherit (lib) nameValuePair mapAttrsToList;
  inherit (builtins) listToAttrs replaceStrings concatMap;
  escapeRuleName = name:
    replaceStrings [ "*" "." "/" ] [ "all" "-" "-" ] name;

  makeAlwaysRuleFile =  rulePath: name': rule: let name = escapeRuleName name'; in
    nameValuePair (rulePath + "/${name}.json") {
      source = writeText name (builtins.toJSON ({
        inherit name;
        enabled = true;
        duration = "always";
      } // rule));
    };

  makeAlwaysOperatorFile = rulePath: name: operator:
    makeAlwaysRuleFile rulePath name {action = "allow"; inherit operator; };

  makePackageRuleFile = rulePath: pkg: let
    name = "nixos-allow-pkg-${lib.strings.getName pkg}";
    in makeAlwaysOperatorFile rulePath name {
          type = "regexp";
          operand = "process.path";
          data = "/nix/store/.*${pkg.name}/.*";
    };

  makeHostRuleFile = rulePath: type: value: let
    name = "nixos-allow-${type}-${value}";
    in makeAlwaysOperatorFile rulePath name {
      type = "regexp";
      operand = "dest.${type}";
      data = replaceStrings [ "." "*" ] [ "\\." ".*" ] value;
    };

in

{

  options = {
    services.opensnitch = with lib; {

      uiConfig = mkOption {
        type = types.attrs;
        description = "JSON attribute set for opensnitch ui config";
        default = {
          default_timeout = 60;
          default_action = "deny";
          default_duration = "once";
        };
      };

      whitelistPackages = mkOption {
        type = types.listOf types.package;
        description = ''
          List of packages for which to generate rules to allow connections
          from all processes that are located below
          a package's store path.  Intended for process rules
          which should survive NixOS updates.
        '';
        default = with pkgs; [ nix ];
      };

      whitelistHosts = mkOption {
        type = types.listOf types.attrs;
        description = ''
          List of destination hosts for which to create default (regexp) allow rules,
          regardless of other connection properties.
        '';
        default = [];
        example = ''[ { host = "*.nixos.org" } { ip = "127.0.0.1" } ]'';
      };

      extraRules = mkOption {
        type = types.attrsOf types.attrs;
        description = ''
          Set of JSON attribute sets describing default opensnitch rules that are written to
          /etc/opensnitch/rules.
        '';
        default = {};
        example = ''
          {
            kerberos = {
              action = "allow";
              operator = {
                type = "list";
                list = [
                  {
                    type = "simple";
                    operand = "dest.host";
                    data = "kerberos.example.domain";
                  }
                  {
                    type = "simple";
                    operand = "dest.port";
                    data = "631";
                  }
                ];
              };
            };
          }
        '';
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
        ++ mapAttrsToList (makeAlwaysRuleFile "opensnitchd/rules") cfg.extraRules
      );

      environment.systemPackages = [ opensnitch-ui ];

      systemd.services.opensnitchd = {
        description = "opensnitch firewall daemon";
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
        # For some reason there is a problem with specifying /run for the socket file...
        # script = "${lib.getBin opensnitch.daemon}/bin/opensnitchd -log-file /var/log/opensnitchd.log -rules-path /etc/opensnitchd/rules -ui-socket unix:///run/opensnitch/osui.sock -debug";
        script = "${lib.getBin opensnitchd}/bin/opensnitchd -log-file /var/log/opensnitchd.log -rules-path /etc/opensnitchd/rules -ui-socket unix:///tmp/osui.sock";
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = "30";
        };
      };
    };
}
